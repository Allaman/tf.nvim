<h1 align="center">tf.nvim</h1>

<div align="center">
  <p>
    <img src="https://img.shields.io/badge/NeoVim-%2357A143.svg?&style=for-the-badge&logo=neovim&logoColor=white" alt="Neovim"/>
    <img src="https://img.shields.io/badge/lua-%232C2D72.svg?style=for-the-badge&logo=lua&logoColor=white" alt="Lua"/>
  </p>
</div>
<div align="center">
  <p>
    <img src="https://github.com/Allaman/tf.nvim/actions/workflows/ci.yml/badge.svg" alt="CI"/>
    <img src="https://img.shields.io/github/repo-size/Allaman/tf.nvim" alt="size"/>
    <img src="https://img.shields.io/github/issues/Allaman/tf.nvim.svg" alt="issues"/>
    <img src="https://img.shields.io/github/last-commit/Allaman/tf.nvim" alt="last commit"/>
    <img src="https://img.shields.io/github/license/Allaman/tf.nvim" alt="license"/>
    <img src="https://img.shields.io/github/v/release/Allaman/tf.nvim?sort=semver" alt="release"/>
  </p>
</div>

A Neovim plugin for

- quickly accessing Terraform provider documentation
- Reading and deleting Terraform state
- Run validation

## Features

- Parse Terraform `resource` and `data` blocks under cursor
  - Support for major providers (AWS, Azure, Google Cloud, and more)
  - Automatically constructs Terraform Registry documentation URLs
  - Configurable provider registry for custom/community providers
  - Copy URL to clipboard OR open directly in browser
  - Configurable browser command
- **View and manage Terraform state** - interactive state browser
  - Filter, search, and copy Terraform state addresses in-place
  - Delete resources from state with confirmation dialog
- Run `terraform validate` without leaving Neovim

## Installation

```lua
{
  "allaman/tf.nvim",
    opts = {},
    ft = "terraform"
}
```

## Usage

### Commands

**Terraform Documentation:**

- `:TerraformDoc` - Uses the configured default action (copy)
- `:TerraformDocCopy` - Always copy URL to clipboard
- `:TerraformDocOpen` - Always open URL in browser

![tf-doc.png](https://s12.gifyu.com/images/bhMLE.png)

**State Management:**

- `:TerraformState` - Open interactive state viewer

**State Management:**

- `:TerraformValidate` - Run `terraform validate` in the detected project root

![ts-state.png](https://s12.gifyu.com/images/bhMLh.png)

### Terraform Documentation

1. Open a Terraform file (`.tf`)
2. Place your cursor anywhere on or inside a `resource` or `data` block
3. Run `:TerraformDoc` (or one of the other commands)
4. The documentation URL will be copied to clipboard or opened in browser

### Terraform State Viewer

The interactive state viewer allows you to browse, inspect, and manage your Terraform state.

#### Opening the State Viewer

Run `:TerraformState` from any directory containing Terraform files. This opens a split window with your state resources. The plugin automatically walks up from the active buffer to find the nearest Terraform root before executing CLI commands, and every operation is launched asynchronously to keep Neovim responsive.

#### Keybindings in State Viewer

| Key       | Action                                         |
| --------- | ---------------------------------------------- |
| `<Enter>` | Show detailed state for resource under cursor  |
| `y`       | Copy resource address to clipboard             |
| `d`       | Delete resource from state (with confirmation) |
| `r`       | Refresh resource list                          |
| `f`       | Prompt for a substring filter                  |
| `F`       | Clear the active filter                        |
| `q`       | Close state viewer                             |
| `g?`      | Show help                                      |

#### Example Workflow

1. Run `:TerraformState`
1. Navigate to a resource using `j/k`
1. `f` to filter resources (if needed)
1. Press `<Enter>` to view details in a split
1. Press d to delete (if needed) with confirmation
1. Press q to close

## Configuration

### Custom Providers

Add or override provider configurations:

```lua
require("tf").setup({
  doc = {
    providers = {
      -- Add a custom provider
      custom = { namespace = "myorg" },

      -- Override a default provider
      aws = { namespace = "custom-aws-fork" },
    }
  }
})
```

### Browser Configuration

**Default browser commands by OS:**

- macOS: `open`
- Linux: `xdg-open`
- Windows: `start`

Configure the default action and browser command:

```lua
require("tf").setup({
  doc = {
    -- Set default action to open in browser instead of copying
    default_action = "open", -- "copy" or "open"

    -- Specify custom browser command (optional, auto-detected if not set)
    -- Accepts either a string or an array of args.
    browser_command = "firefox", -- or { "open", "-a", "Safari" }, "brave", etc.
  }
})
```

### Terraform CLI Configuration

Override Terraform binary (e.g. when not in PATH)

```lua
require("tf").setup({
  terraform = {
    bin = "/opt/homebrew/bin/terraform",
  },
})
```

### Filetype Configuration

Control which filetypes can trigger documentation lookups (defaults include `terraform`, `tf`, `terraform-vars`, `tfvars`, and `hcl`):

```lua
require("tf").setup({
  filetypes = { "terraform", "tf", "terraform-vars", "tfvars", "hcl" },
})
```

### State Viewer Options

Tune filtering and detail view behavior:

```lua
require("tf").setup({
  state = {
    filter = { case_sensitive = true },
    detail = { folds = true, foldmethod = "syntax" },
    window = {
      mode = "float", -- "vsplit" (default), "split", or "float"
      split = { position = "botright", size = 80 },
      float = { width = 0.7, height = 0.8 },
      focus = false,
    },
  },
})
```

### Key Mappings

You can create keymaps for quick access:

```lua
vim.keymap.set("n", "<leader>td", ":TerraformDoc<cr>", { desc = "Terraform Documentation" })
vim.keymap.set("n", "<leader>tc", ":TerraformDocCopy<cr>", { desc = "Terraform Doc (Copy)" })
vim.keymap.set("n", "<leader>to", ":TerraformDocOpen<cr>", { desc = "Terraform Doc (Open)" })
vim.keymap.set("n", "<leader>ts", ":TerraformState<cr>", { desc = "Terraform State" })
vim.keymap.set("n", "<leader>tv", ":TerraformValidate<cr>", { desc = "Terraform Validate" })
```

## Supported Providers

The plugin includes built-in support for:

### HashiCorp Official

- aws, azurerm, azuread, google, kubernetes, helm
- random, null, template, local, tls
- vault, consul, nomad

### Community Providers

- datadog, cloudflare, digitalocean
- mongodbatlas, github, gitlab
- auth0, okta, snowflake, databricks

For providers not in the list, the plugin will default to the `hashicorp` namespace. You can add custom providers via configuration.

## Requirements

- Neovim 0.11+
- Clipboard support (`:checkhealth` and look for "Clipboard") - for documentation copy feature
- `terraform` CLI - for state viewer and validation feature

## License

MIT

## Related Projects

- [mvaldes14/terraform.nvim](https://github.com/mvaldes14/terraform.nvim) - Similar to tf.nvim but lacks the doc feature
- [dakota-m/terraform.nvim](https://github.com/dakota-m/terraform.nvim) - Similar to tf.nvim but lacks the doc feature
- [vim-terraform](https://github.com/hashivim/vim-terraform) - Terraform filetype plugin
