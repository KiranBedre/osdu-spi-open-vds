/****************************************************************************
** Copyright (c) Microsoft Corporation.
****************************************************************************/

#include "WorkloadIdentityTokenSource.h"
#include "IO/DmsIoFactories/DmsIoManagerFactory.h"
#include "VDS/Logging.h"

#include <fmt/format.h>
#include <azure/identity.hpp>
#include <azure/core/credentials/credentials.hpp>
#include <exception>
#include <string>

namespace OpenVDS
{

// Fetch an Azure AD access token using Azure Identity SDK.
// DefaultAzureCredential automatically detects the environment and uses
// the appropriate credential type (Workload Identity, Managed Identity, etc.)
std::string FetchWorkloadIdentityToken(const std::string& scope)
{
  // Prepare logger for diagnostic output
  Logger logger(static_cast<GlobalStateImpl*>(OpenVDS::GetGlobalState())->logInterface, LogLevel::Info);
  logger.LogInfo("FetchWorkloadIdentityToken: start");
  logger.LogInfo(std::string("FetchWorkloadIdentityToken: requesting scope: ") + scope);

  try
  {
    // Use WorkloadIdentityCredential for explicit workload identity authentication.
    // This will only use the federated token from the pod's service account.
    auto credential = std::make_shared<Azure::Identity::WorkloadIdentityCredential>();
    
    logger.LogInfo("FetchWorkloadIdentityToken: created WorkloadIdentityCredential");

    // Prepare the token request context with the desired scope
    Azure::Core::Credentials::TokenRequestContext tokenContext;
    tokenContext.Scopes.push_back(scope);

    // Request the token - this is a blocking call
    logger.LogInfo("FetchWorkloadIdentityToken: requesting token...");
    auto tokenResult = credential->GetToken(tokenContext, Azure::Core::Context());

    // Extract the token string from the result
    std::string token = tokenResult.Token;
    
    if (token.empty())
    {
      logger.LogError("FetchWorkloadIdentityToken: received empty token");
      return std::string();
    }

    logger.LogInfo(std::string("FetchWorkloadIdentityToken: obtained token, length=") + std::to_string(token.size()));
    
    // Log token expiration time
    auto expiresOn = tokenResult.ExpiresOn;
    auto now = std::chrono::system_clock::now();
    auto duration = std::chrono::duration_cast<std::chrono::seconds>(static_cast<std::chrono::system_clock::time_point>(expiresOn) - now);
    if (duration.count() < 0)
    {
      logger.LogError("FetchWorkloadIdentityToken: token is already expired or clock skew detected");
    }
    else
    {
      logger.LogInfo(std::string("FetchWorkloadIdentityToken: token expires in ") + std::to_string(duration.count()) + " seconds");
    }

    return tokenResult.Token;
  }
  catch (const Azure::Core::Credentials::AuthenticationException& ex)
  {
    logger.LogError(std::string("FetchWorkloadIdentityToken: authentication failed: ") + ex.what());
    return std::string();
  }
  catch (...)
  {
    logger.LogError("FetchWorkloadIdentityToken: unknown error occurred");
    return std::string();
  }
}

} // namespace OpenVDS
