/****************************************************************************
** Copyright (c) Microsoft Corporation.
****************************************************************************/

#pragma once

#include <string>

namespace OpenVDS
{
// Fetch an Azure AD access token using Azure Identity SDK.
// This function uses Azure::Identity::DefaultAzureCredential which automatically
// detects and uses the best available credential provider:
// - Workload Identity (in Kubernetes with federated service account)
// - Managed Identity (in Azure VMs/App Services)
// - Azure CLI credentials (for local development)
// - Environment variables (AZURE_CLIENT_ID, AZURE_TENANT_ID, etc.)
//
// Returns empty string on failure. This function performs blocking HTTP calls.
//
// When running in Kubernetes with Azure Workload Identity:
// - The pod's service account must have the annotation:
//   azure.workload.identity/client-id: <your-client-id>
// - The pod must have the label:
//   azure.workload.identity/use: "true"
std::string FetchWorkloadIdentityToken(const std::string& scope = "https://management.azure.com/.default");

} // namespace OpenVDS
