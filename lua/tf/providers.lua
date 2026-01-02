local M = {}

-- Provider configuration with namespace information
-- Users can extend this via setup()
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

M.exceptions = {
  google_project_iam = { provider = "google", sarch_term = "project_iam", overwrite = "google_project_iam" },
}

--- Get provider configuration
--- @param provider string
--- @return table|nil
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
    -- find if resource needs an exception
    if string.find(resource, config.sarch_term) then
      -- check if resource and exception provider match
      if provider == config.provider then
        return config.overwrite
      end
    end
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
--- @param config table
function M.add_provider(provider, config)
  M.providers[provider] = config
end

--- Merge user-provided providers with defaults
--- @param user_providers table
function M.merge_providers(user_providers)
  if not user_providers then
    return
  end

  for provider, config in pairs(user_providers) do
    M.providers[provider] = config
  end
end

return M
