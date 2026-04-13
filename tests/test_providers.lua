local providers = require("tf.providers")

local T = MiniTest.new_set()

local defaults

T["tf.providers.construct_url"] = MiniTest.new_set({
  hooks = {
    pre_case = function()
      defaults = vim.deepcopy(providers.providers)
    end,
    post_case = function()
      providers.providers = vim.deepcopy(defaults)
    end,
  },
})

T["tf.providers.construct_url"]["builds resource URL for known provider"] = function()
  local block = {
    type = "resource",
    provider = "aws",
    resource_name = "instance",
  }

  local url = providers.construct_url(block)
  MiniTest.expect.equality(url, "https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance")
end

T["tf.providers.construct_url"]["builds data source URL with data-sources path"] = function()
  local block = {
    type = "data",
    provider = "google",
    resource_name = "compute_instance",
  }

  local url = providers.construct_url(block)
  MiniTest.expect.equality(
    url,
    "https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/compute_instance"
  )
end

T["tf.providers.construct_url"]["defaults to hashicorp namespace when provider is unknown"] = function()
  local block = {
    type = "resource",
    provider = "custom",
    resource_name = "thing",
  }

  local url = providers.construct_url(block)
  MiniTest.expect.equality(
    url,
    "https://registry.terraform.io/providers/hashicorp/custom/latest/docs/resources/thing"
  )
end

T["tf.providers.construct_url"]["uses merged provider namespace overrides"] = function()
  providers.merge_providers({
    custom = { namespace = "mycorp" },
  })

  local block = {
    type = "resource",
    provider = "custom",
    resource_name = "feature",
  }

  local url = providers.construct_url(block)
  MiniTest.expect.equality(
    url,
    "https://registry.terraform.io/providers/mycorp/custom/latest/docs/resources/feature"
  )
end

T["tf.providers.construct_url"]["google resource without prefix produces unprefixed URL"] = function()
  local block = {
    type = "resource",
    provider = "google",
    resource_name = "compute_instance",
  }

  local url = providers.construct_url(block)
  MiniTest.expect.equality(
    url,
    "https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_instance"
  )
end

T["tf.providers.construct_url"]["google resource in google_prefixed list gets google_ prefix"] = function()
  local block = {
    type = "resource",
    provider = "google",
    resource_name = "service_account",
  }

  local url = providers.construct_url(block)
  MiniTest.expect.equality(
    url,
    "https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/google_service_account"
  )
end

T["tf.providers.construct_url"]["google_project_iam_member resolves to shared google_project_iam page"] = function()
  local block = {
    type = "resource",
    provider = "google",
    resource_name = "project_iam_member",
  }

  local url = providers.construct_url(block)
  MiniTest.expect.equality(
    url,
    "https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/google_project_iam"
  )
end

T["tf.providers.construct_url"]["google_project_iam_binding resolves to shared google_project_iam page"] = function()
  local block = {
    type = "resource",
    provider = "google",
    resource_name = "project_iam_binding",
  }

  local url = providers.construct_url(block)
  MiniTest.expect.equality(
    url,
    "https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/google_project_iam"
  )
end

T["tf.providers.construct_url"]["google_project_iam_policy resolves to shared google_project_iam page"] = function()
  local block = {
    type = "resource",
    provider = "google",
    resource_name = "project_iam_policy",
  }

  local url = providers.construct_url(block)
  MiniTest.expect.equality(
    url,
    "https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/google_project_iam"
  )
end

T["tf.providers.construct_url"]["google_project_iam_member_remove is not caught by project_iam_member exception"] =
  function()
    local block = {
      type = "resource",
      provider = "google",
      resource_name = "project_iam_member_remove",
    }

    local url = providers.construct_url(block)
    MiniTest.expect.equality(
      url,
      "https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/google_project_iam_member_remove"
    )
  end

return T
