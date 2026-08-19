#This file depends on being in open-vds/CMake directory
set(Fetch3rdPartyDirInternal "${CMAKE_CURRENT_LIST_DIR}")

macro(Fetch3rdParty_File name dir_prefix version ext url url_hash)
  if (OPENVDS_3RD_PARTY_DIR)
    set(Fetch3rdPartyDir "${OPENVDS_3RD_PARTY_DIR}")
  else()
    set(Fetch3rdPartyDir "${Fetch3rdPartyDirInternal}/../3rdparty")
  endif()
  get_filename_component(thirdParty "${Fetch3rdPartyDir}/${dir_prefix}" ABSOLUTE)
  file(MAKE_DIRECTORY ${thirdParty})
  set(SRC_FILE ${thirdParty}/${name}-${version}.${ext})
  set(${name}_SOURCE_FILE ${SRC_FILE} PARENT_SCOPE)
  set(${name}_VERSION ${version} PARENT_SCOPE)
  if (NOT (EXISTS ${SRC_FILE}))
    file(DOWNLOAD ${url}
      ${SRC_FILE}
      SHOW_PROGRESS
      EXPECTED_HASH ${url_hash}
      )
  endif()
endmacro()

macro(Fetch3rdParty_FileTarget name dir_prefix dest version url url_hash)
  if (OPENVDS_3RD_PARTY_DIR)
    set(Fetch3rdPartyDir "${OPENVDS_3RD_PARTY_DIR}")
  else()
    set(Fetch3rdPartyDir "${Fetch3rdPartyDirInternal}/../3rdparty")
  endif()
  get_filename_component(thirdParty "${Fetch3rdPartyDir}/${name}-${version}/${dir_prefix}" ABSOLUTE)
  file(MAKE_DIRECTORY ${thirdParty})
  set(DEST_FILE ${thirdParty}/${dest})
  set(${name}_SOURCE_FILE ${DEST_FILE} PARENT_SCOPE)
  set(${name}_SOURCE_DIR  ${Fetch3rdPartyDir}/${name}-${version} PARENT_SCOPE)
  set(${name}_VERSION ${version} PARENT_SCOPE)
  if (NOT (EXISTS ${DEST_FILE}))
    file(DOWNLOAD ${url}
      ${DEST_FILE}
      SHOW_PROGRESS
      EXPECTED_HASH ${url_hash}
      )
  endif()

endmacro()

macro(Fetch3rdParty_Package name version url url_hash)
  if (OPENVDS_3RD_PARTY_DIR)
    set(Fetch3rdPartyDir "${OPENVDS_3RD_PARTY_DIR}")
  else()
    set(Fetch3rdPartyDir "${Fetch3rdPartyDirInternal}/../3rdparty")
  endif()
    get_filename_component(thirdParty "${Fetch3rdPartyDir}" ABSOLUTE)
    set(SRC_DIR ${thirdParty}/${name}-${version})
    set(${name}_SOURCE_DIR ${SRC_DIR} PARENT_SCOPE)
    set(${name}_VERSION ${version} PARENT_SCOPE)
  if (NOT (EXISTS ${SRC_DIR}))
    FetchContent_Populate(${name}
      URL ${url}
      URL_HASH ${url_hash}
      LOG_PATCH ON
      PATCH_COMMAND ${${name}_patch}
      SOURCE_DIR ${SRC_DIR}
      SUBBUILD_DIR ${thirdParty}/CMakeArtifacts/${name}-sub-${version}
      BINARY_DIR ${thirdParty}/CMakeArtifacts/${name}-${version})
  endif()
endmacro()

macro(Fetch3rdParty_Git name version url tag)
  if (OPENVDS_3RD_PARTY_DIR)
    set(Fetch3rdPartyDir "${OPENVDS_3RD_PARTY_DIR}")
  else()
    set(Fetch3rdPartyDir "${Fetch3rdPartyDirInternal}/../3rdparty")
  endif()
    get_filename_component(thirdParty "${Fetch3rdPartyDir}" ABSOLUTE)
    set(SRC_DIR ${thirdParty}/${name}-${version})
    set(${name}_SOURCE_DIR ${SRC_DIR} PARENT_SCOPE)
    set(${name}_VERSION ${version} PARENT_SCOPE)
  if (NOT (EXISTS ${SRC_DIR}))
    FetchContent_Populate(${name}
      GIT_REPOSITORY ${url}
      GIT_TAG ${tag}
      GIT_SHALLOW ON
      SOURCE_DIR ${SRC_DIR}
      SUBBUILD_DIR ${thirdParty}/CMakeArtifacts/${name}-sub-${version}
      BINARY_DIR ${thirdParty}/CMakeArtifacts/${name}-${version})
  endif()
endmacro()


function(Fetch3rdParty)
  set(FETCHCONTENT_QUIET OFF)
  include(FetchContent)

  if (OPENVDS_3RD_PARTY_DIR)
    set(Fetch3rdPartyDir "${OPENVDS_3RD_PARTY_DIR}")
  else()
    set(Fetch3rdPartyDir "${Fetch3rdPartyDirInternal}/../3rdparty")
  endif()

  set(azure-sdk-for-cpp_patch git --git-dir= apply --ignore-whitespace --ignore-space-change --unsafe-paths -v --directory ${Fetch3rdPartyDir}/azure-sdk-for-cpp-1.16.0 ${Fetch3rdPartyDirInternal}/../3rdparty/BuildAzureSdkForCpp/0001-Fix-use-of-namespace-qualifiers-for-VS2017.patch)

  Fetch3rdParty_Git(aws-crt-cpp           0.19.8     https://github.com/awslabs/aws-crt-cpp.git                                           v0.19.8)
  Fetch3rdParty_Package(gtest             1.12.1     https://github.com/google/googletest/archive/refs/tags/release-1.12.1.tar.gz         SHA256=81964fe578e9bd7c94dfdb09c8e4d6e6759e19967e397dbea48d1c10e45d0df2)
  Fetch3rdParty_Package(benchmark         1.6.1      https://github.com/google/benchmark/archive/refs/tags/v1.6.1.tar.gz                  SHA256=6132883bc8c9b0df5375b16ab520fac1a85dc9e4cf5be59480448ece74b278d4)
  Fetch3rdParty_Package(jsoncpp           1.8.4      https://github.com/open-source-parsers/jsoncpp/archive/1.8.4.tar.gz                  MD5=fa47a3ab6b381869b6a5f20811198662)
  Fetch3rdParty_Package(fmt               11.0.2     https://github.com/fmtlib/fmt/archive/refs/tags/11.0.2.tar.gz                        SHA256=6cb1e6d37bdcb756dbbe59be438790db409cdb4868c66e888d5df9f13f7c027f)
  Fetch3rdParty_Package(pybind11          2.12.0     https://github.com/pybind/pybind11/archive/v2.12.0.tar.gz                            SHA256=bf8f242abd1abcd375d516a7067490fb71abd79519a282d22b6e4d19282185a7)
  Fetch3rdParty_Package(curl              8.21.0     https://github.com/curl/curl/releases/download/curl-8_21_0/curl-8.21.0.tar.gz        SHA256=d9b327997999045a24cda50f3983e69e51c516bd8be6ef9842fc7f99135e33bb)
  Fetch3rdParty_Package(libuv             1.44.2     https://github.com/libuv/libuv/archive/v1.44.2.tar.gz                                SHA256=e6e2ba8b4c349a4182a33370bb9be5e23c51b32efb9b9e209d0e8556b73a48da)
  Fetch3rdParty_Package(zlib              1.3.1      https://github.com/madler/zlib/archive/v1.3.1.tar.gz                                 SHA256=17e88863f3600672ab49182f217281b6fc4d3c762bde361935e436a95214d05c)
  Fetch3rdParty_Package(libressl          3.6.2      https://cdn.openbsd.org/pub/OpenBSD/LibreSSL/libressl-3.6.2.tar.gz                   SHA256=4be80fff073746cf50b4a8e5babe2795acae98c6b132a9e02519b445dfbfd033)
  Fetch3rdParty_Package(openssl           3.0.12     https://www.openssl.org/source/openssl-3.0.12.tar.gz                                 SHA256=f93c9e8edde5e9166119de31755fc87b4aa34863662f67ddfcba14d0b6b69b61)
  Fetch3rdParty_Package(absl              20230125.4 https://codeload.github.com/abseil/abseil-cpp/tar.gz/20230125.4                      SHA256=50fc2189ddccd08a0134c6dd51869aff8e93a3342e7d3201f0ca1a4622c30ac1)
  Fetch3rdParty_Package(crc32c            1.1.2      https://codeload.github.com/google/crc32c/tar.gz/1.1.2                               SHA256=ac07840513072b7fcebda6e821068aa04889018f24e10e46181068fb214d7e56)
  Fetch3rdParty_Package(google-cloud-cpp  2.20.0     https://github.com/googleapis/google-cloud-cpp/archive/refs/tags/v2.20.0.tar.gz      SHA256=0f42208ca782249555aac06455b1669c17dfb31d6d8fa4baad29a90f295666bb)
  Fetch3rdParty_Package(libxml2           2.9.12a    https://codeload.github.com/GNOME/libxml2/tar.gz/v2.9.12                             SHA256=8a4ddd706419c210b30b8978a51388937fd9362c34fc9a3d69e4fcc6f8055ee0)
  Fetch3rdParty_Package(azure-sdk-for-cpp 1.16.0     https://github.com/Azure/azure-sdk-for-cpp/archive/refs/tags/azure-core_1.16.0.tar.gz SHA256=7F8BA547EF67290075CE148BA1769CF43AA9C7AEED1A62AC5F7AB521F6E68724)
  Fetch3rdParty_File(testng  java         6.14.3 jar https://repo1.maven.org/maven2/org/testng/testng/6.14.3/testng-6.14.3.jar            MD5=9f17a8f9e99165e148c42b21f4b63d7c)
  Fetch3rdParty_File(jcommander java      1.72 jar   https://repo1.maven.org/maven2/com/beust/jcommander/1.72/jcommander-1.72.jar         MD5=9fde6bc0ba1032eceb7267fd1ad1657b)
  Fetch3rdParty_FileTarget(google_nlohmann nlohmann json.hpp 3.9.1  https://raw.githubusercontent.com/nlohmann/json/v3.9.1/single_include/nlohmann/json.hpp MD5=5eabadfb8cf8fe1bf0811535c65f027f)
  Fetch3rdParty_Package(cmakerc           e7ba9e     https://github.com/vector-of-bool/cmrc/archive/e7ba9e9417960b2a5cefc9e79e8af8b06bfde3d1.zip SHA256=75c1263bb37b8bae159bacb4da10fd2eb50b9c04118901218b6a817b9d0fa757)
  Fetch3rdParty_Package(cxxopts           3.3.1      https://github.com/jarro2783/cxxopts/archive/refs/tags/v3.3.1.tar.gz SHA256=3bfc70542c521d4b55a46429d808178916a579b28d048bd8c727ee76c39e2072)
  Fetch3rdParty_Package(sse2neon          1.5.1      https://github.com/DLTcollab/sse2neon/archive/refs/tags/v1.5.1.tar.gz SHA256=4001e2dfb14fcf3831211581ed83bcc83cf6a3a69f638dcbaa899044a351bb2a)
  if(WIN32)
    Fetch3rdParty_Package(wil             1.0.250325.1  https://github.com/microsoft/wil/archive/refs/tags/v1.0.250325.1.tar.gz SHA256=c9e667d5f86ded43d17b5669d243e95ca7b437e3a167c170805ffd4aa8a9a786)
  endif()

endfunction()

