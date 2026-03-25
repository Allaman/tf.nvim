---@class tf.ProviderOverride
---@field provider string
---@field sarch_term string
---@field overwrite string

local M = {}

--- @type table<string, tf.Provider>
M.providers = {
  -- HashiCorp official providers
  aws = { namespace = "hashicorp" },
  azurerm = { namespace = "hashicorp" },
  azuread = { namespace = "hashicorp" },
  google = { namespace = "hashicorp" },
  kubernetes = { namespace = "hashicorp" },
  helm = { namespace = "hashicorp" },
  random = { namespace = "hashicorp" },
  null = { namespace = "hashicorp" },
  template = { namespace = "hashicorp" },
  ["local"] = { namespace = "hashicorp" },
  tls = { namespace = "hashicorp" },
  vault = { namespace = "hashicorp" },
  consul = { namespace = "hashicorp" },
  nomad = { namespace = "hashicorp" },

  -- Popular community providers
  datadog = { namespace = "DataDog" },
  cloudflare = { namespace = "cloudflare" },
  digitalocean = { namespace = "digitalocean" },
  mongodbatlas = { namespace = "mongodb" },
  github = { namespace = "integrations" },
  gitlab = { namespace = "gitlabhq" },
  auth0 = { namespace = "auth0" },
  okta = { namespace = "okta" },
  snowflake = { namespace = "Snowflake-Labs" },
  databricks = { namespace = "databricks" },
}

--- @type table<string, tf.ProviderOverride>
M.exceptions = {
  -- google_project_iam_member and _binding/_policy all share one doc page
  google_project_iam_member = {
    provider = "google",
    sarch_term = "project_iam_member",
    overwrite = "google_project_iam",
  },
  google_project_iam_binding = {
    provider = "google",
    sarch_term = "project_iam_binding",
    overwrite = "google_project_iam",
  },
  google_project_iam_policy = {
    provider = "google",
    sarch_term = "project_iam_policy",
    overwrite = "google_project_iam",
  },
}

-- Google provider docs are inconsistent: some resource/data-source doc pages are
-- prefixed with "google_" in the URL, others are not.
-- See https://github.com/hashicorp/terraform-provider-google/issues/25684
-- These are the known affected resource_names (after stripping the "google_" provider prefix).
local google_prefixed = {
  billing_subaccount = true,
  folder = true,
  folder_iam = true,
  folder_organization_policy = true,
  kms_crypto_key_iam = true,
  kms_key_ring_iam = true,
  organization_iam = true,
  organization_iam_custom_role = true,
  organization_policy = true,
  project = true,
  project_default_service_accounts = true,
  project_iam = true,
  project_iam_custom_role = true,
  project_iam_member_remove = true,
  project_organization_policy = true,
  project_service = true,
  service_account = true,
  service_account_iam = true,
  service_account_key = true,
  service_networking_peered_dns_domain = true,
  tags_location_tag_binding = true,
  vertex_ai_index = true, -- data source only
}

--- Get provider configuration
--- @param provider string
--- @return tf.Provider|nil
local function get_provider_config(provider)
  return M.providers[provider]
end

--- Convert resource type to URL path component
--- For data sources, we need "data-sources" path
--- For resources, we need "resources" path
--- @param block_type string -- "resource" or "data"
--- @return string
local function get_doc_type_path(block_type)
  if block_type == "data" then
    return "data-sources"
  else
    return "resources"
  end
end

--- Handle exceptions
--- @param resource string
--- @param provider string
--- @return string|nil
local function handle_exceptions(resource, provider)
  for _, config in pairs(M.exceptions) do
    if resource == config.sarch_term and provider == config.provider then
      return config.overwrite
    end
  end

  if provider == "google" and google_prefixed[resource] then
    return "google_" .. resource
  end

  return nil
end

--- Construct documentation URL for a Terraform resource or data source
--- @param block table -- Parsed block info from parser
--- @return string|nil
function M.construct_url(block)
  if not block or not block.provider or not block.resource_name then
    return nil
  end

  local config = get_provider_config(block.provider)
  local namespace = config and config.namespace or "hashicorp"

  local doc_type = get_doc_type_path(block.type)

  local resource_name = handle_exceptions(block.resource_name, block.provider) or block.resource_name

  -- Construct URL following Terraform Registry pattern
  return string.format(
    "https://registry.terraform.io/providers/%s/%s/latest/docs/%s/%s",
    namespace,
    block.provider,
    doc_type,
    resource_name
  )
end

--- Add or update a custom provider
--- @param provider string
--- @param config tf.Provider
function M.add_provider(provider, config)
  M.providers[provider] = config
end

--- Merge user-provided providers with defaults
--- @param user_providers table<string, tf.Provider>
function M.merge_providers(user_providers)
  if not user_providers then
    return
  end

  for provider, config in pairs(user_providers) do
    M.providers[provider] = config
  end
end

return M
