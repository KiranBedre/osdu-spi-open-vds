/****************************************************************************
** Copyright 2026 The Open Group
** Copyright 2026 Bluware, Inc.
**
** Licensed under the Apache License, Version 2.0 (the "License");
** you may not use this file except in compliance with the License.
** You may obtain a copy of the License at
**
**     http://www.apache.org/licenses/LICENSE-2.0
**
** Unless required by applicable law or agreed to in writing, software
** distributed under the License is distributed on an "AS IS" BASIS,
** WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
** See the License for the specific language governing permissions and
** limitations under the License.
****************************************************************************/

#include <IO/IOManagerCurl.h>
#include <VDS/GlobalStateImpl.h>

#include <gtest/gtest.h>

#ifndef _WIN32
#include <sys/socket.h>
#include <unistd.h>
#endif

namespace
{

int countActivePollHandles(uv_loop_t *loop)
{
  int count = 0;
  uv_walk(loop, [](uv_handle_t *handle, void *arg)
  {
    if (handle->type == UV_POLL && uv_is_active(handle))
      ++(*static_cast<int *>(arg));
  }, &count);
  return count;
}

OpenVDS::SocketContext *findSocketContext(uv_loop_t *loop)
{
  OpenVDS::SocketContext *found = nullptr;
  uv_walk(loop, [](uv_handle_t *handle, void *arg)
  {
    if (handle->type == UV_POLL)
      *static_cast<OpenVDS::SocketContext **>(arg) = static_cast<OpenVDS::SocketContext *>(handle->data);
  }, &found);
  return found;
}

void closeTestSocket(curl_socket_t s)
{
#ifdef _WIN32
  closesocket(s);
#else
  close(s);
#endif
}

}

// Since curl 8.10.0 CURLMOPT_SOCKETFUNCTION can be invoked for easy handles
// created internally by libcurl (connection eyeballing/shutdown). Those
// handles have no CURLOPT_PRIVATE set, so CURLINFO_PRIVATE returns null.
// The callback must not crash on them, and it must still poll their sockets,
// otherwise the transfers they drive stall and time out.
TEST(IOManagerCurl, socketCallbackForInternalEasyHandle)
{
  ASSERT_EQ(curl_global_init(CURL_GLOBAL_ALL), CURLE_OK);

  OpenVDS::GlobalLogInterface logInterface;
  OpenVDS::Logger logger(logInterface, OpenVDS::LogLevel::None);
  OpenVDS::UVEventLoopData eventLoopData(logger, std::string());

  uv_loop_t loop;
  ASSERT_EQ(uv_loop_init(&loop), 0);
  eventLoopData.loop = &loop;
  eventLoopData.curlMulti = curl_multi_init();
  ASSERT_NE(eventLoopData.curlMulti, nullptr);

  CURL *internalEasy = curl_easy_init();
  ASSERT_NE(internalEasy, nullptr);

  curl_socket_t s = socket(AF_INET, SOCK_DGRAM, 0);
  ASSERT_NE(s, CURL_SOCKET_BAD);

  EXPECT_EQ(OpenVDS::curlSocketCB(internalEasy, s, CURL_POLL_IN, &eventLoopData, nullptr), 0);
  EXPECT_EQ(countActivePollHandles(&loop), 1);

  OpenVDS::SocketContext *socketContext = findSocketContext(&loop);
  ASSERT_NE(socketContext, nullptr);
  EXPECT_EQ(OpenVDS::curlSocketCB(internalEasy, s, CURL_POLL_REMOVE, &eventLoopData, socketContext), 0);

  uv_run(&loop, UV_RUN_DEFAULT);
  EXPECT_EQ(countActivePollHandles(&loop), 0);

  curl_easy_cleanup(internalEasy);
  curl_multi_cleanup(eventLoopData.curlMulti);
  closeTestSocket(s);
  EXPECT_EQ(uv_loop_close(&loop), 0);
  curl_global_cleanup();
}
