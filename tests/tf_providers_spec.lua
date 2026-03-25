local providers = require("tf.providers")

describe("tf.providers.construct_url", function()
  local defaults

  before_each(function()
    defaults = vim.deepcopy(providers.providers)
  end)

  after_each(function()
    providers.providers = vim.deepcopy(defaults)
  end)

  it("builds resource URL for known provider", function()
    local block = {
      type = "resource",
      provider = "aws",
      resource_name = "instance",
    }

    local url = providers.construct_url(block)
    assert.equals("https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance", url)
  end)

  it("builds data source URL with data-sources path", function()
    local block = {
      type = "data",
      provider = "google",
      resource_name = "compute_instance",
    }

    local url = providers.construct_url(block)
    assert.equals(
      "https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/compute_instance",
      url
    )
  end)

  it("defaults to hashicorp namespace when provider is unknown", function()
    local block = {
      type = "resource",
      provider = "custom",
      resource_name = "thing",
    }

    local url = providers.construct_url(block)
    assert.equals("https://registry.terraform.io/providers/hashicorp/custom/latest/docs/resources/thing", url)
  end)

  it("uses merged provider namespace overrides", function()
    providers.merge_providers({
      custom = { namespace = "mycorp" },
    })

    local block = {
      type = "resource",
      provider = "custom",
      resource_name = "feature",
    }

    local url = providers.construct_url(block)
    assert.equals("https://registry.terraform.io/providers/mycorp/custom/latest/docs/resources/feature", url)
  end)

  it("google resource without prefix produces unprefixed URL", function()
    local block = {
      type = "resource",
      provider = "google",
      resource_name = "compute_instance",
    }

    local url = providers.construct_url(block)
    assert.equals(
      "https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_instance",
      url
    )
  end)

  it("google resource in google_prefixed list gets google_ prefix", function()
    local block = {
      type = "resource",
      provider = "google",
      resource_name = "service_account",
    }

    local url = providers.construct_url(block)
    assert.equals(
      "https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/google_service_account",
      url
    )
  end)

  it("google_project_iam_member resolves to shared google_project_iam page", function()
    local block = {
      type = "resource",
      provider = "google",
      resource_name = "project_iam_member",
    }

    local url = providers.construct_url(block)
    assert.equals(
      "https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/google_project_iam",
      url
    )
  end)

  it("google_project_iam_binding resolves to shared google_project_iam page", function()
    local block = {
      type = "resource",
      provider = "google",
      resource_name = "project_iam_binding",
    }

    local url = providers.construct_url(block)
    assert.equals(
      "https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/google_project_iam",
      url
    )
  end)

  it("google_project_iam_policy resolves to shared google_project_iam page", function()
    local block = {
      type = "resource",
      provider = "google",
      resource_name = "project_iam_policy",
    }

    local url = providers.construct_url(block)
    assert.equals(
      "https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/google_project_iam",
      url
    )
  end)

  it("google_project_iam_member_remove is not caught by project_iam_member exception", function()
    local block = {
      type = "resource",
      provider = "google",
      resource_name = "project_iam_member_remove",
    }

    local url = providers.construct_url(block)
    assert.equals(
      "https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/google_project_iam_member_remove",
      url
    )
  end)
end)
