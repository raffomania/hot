defmodule HotWeb.Components.MishkaComponents do
  defmacro __using__(_) do
    quote do
      import HotWeb.Components.Accordion,
        only: [
          accordion: 1,
          native_accordion: 1,
          show_accordion_content: 1,
          show_accordion_content: 2,
          hide_accordion_content: 1,
          hide_accordion_content: 2
        ]

      import HotWeb.Components.Alert,
        only: [
          flash: 1,
          flash_group: 1,
          alert: 1,
          show_alert: 1,
          show_alert: 2,
          hide_alert: 1,
          hide_alert: 2
        ]

      import HotWeb.Components.Avatar, only: [avatar: 1, avatar_group: 1]

      import HotWeb.Components.Badge,
        only: [badge: 1, hide_badge: 1, hide_badge: 2, show_badge: 1, show_badge: 2]

      import HotWeb.Components.Banner,
        only: [banner: 1, show_banner: 1, show_banner: 2, hide_banner: 1, hide_banner: 2]

      import HotWeb.Components.Blockquote, only: [blockquote: 1]
      import HotWeb.Components.Breadcrumb, only: [breadcrumb: 1]

      import HotWeb.Components.Button,
        only: [button_group: 1, button: 1, input_button: 1, button_link: 1, back: 1]

      import HotWeb.Components.Card,
        only: [card: 1, card_title: 1, card_media: 1, card_content: 1, card_footer: 1]

      import HotWeb.Components.Carousel, only: [carousel: 1]
      import HotWeb.Components.Chat, only: [chat: 1, chat_section: 1]
      import HotWeb.Components.CheckboxCard, only: [checkbox_card: 1, checkbox_card_check: 3]

      import HotWeb.Components.CheckboxField,
        only: [checkbox_field: 1, group_checkbox: 1, checkbox_check: 3]

      import HotWeb.Components.Clipboard, only: [clipboard: 1]
      import HotWeb.Components.ColorField, only: [color_field: 1]
      import HotWeb.Components.Combobox, only: [combobox: 1]
      import HotWeb.Components.DateTimeField, only: [date_time_field: 1]
      import HotWeb.Components.DeviceMockup, only: [device_mockup: 1]
      import HotWeb.Components.Divider, only: [divider: 1, hr: 1]

      import HotWeb.Components.Drawer,
        only: [drawer: 1, hide_drawer: 2, hide_drawer: 3, show_drawer: 2, show_drawer: 3]

      import HotWeb.Components.Dropdown,
        only: [dropdown: 1, dropdown_trigger: 1, dropdown_content: 1]

      import HotWeb.Components.EmailField, only: [email_field: 1]
      import HotWeb.Components.Fieldset, only: [fieldset: 1]
      import HotWeb.Components.FileField, only: [file_field: 1]
      import HotWeb.Components.Footer, only: [footer: 1, footer_section: 1]
      import HotWeb.Components.FormWrapper, only: [form_wrapper: 1, simple_form: 1]

      import HotWeb.Components.Gallery,
        only: [gallery: 1, gallery_media: 1, filterable_gallery: 1]

      import HotWeb.Components.Icon, only: [icon: 1]
      import HotWeb.Components.Image, only: [image: 1]
      import HotWeb.Components.Indicator, only: [indicator: 1]
      import HotWeb.Components.InputField, only: [input: 1, error: 1]
      import HotWeb.Components.Jumbotron, only: [jumbotron: 1]
      import HotWeb.Components.Keyboard, only: [keyboard: 1]
      import HotWeb.Components.Layout, only: [flex: 1, grid: 1]
      import HotWeb.Components.List, only: [list: 1, li: 1, ul: 1, ol: 1, list_group: 1]
      import HotWeb.Components.MegaMenu, only: [mega_menu: 1]
      import HotWeb.Components.Menu, only: [menu: 1]

      import HotWeb.Components.Modal,
        only: [
          modal: 1,
          show_modal: 1,
          show_modal: 2,
          hide_modal: 1,
          hide_modal: 2,
          show: 1,
          show: 2,
          hide: 1,
          hide: 2
        ]

      import HotWeb.Components.NativeSelect, only: [native_select: 1, select_option_group: 1]
      import HotWeb.Components.Navbar, only: [navbar: 1, header: 1]
      import HotWeb.Components.NumberField, only: [number_field: 1]
      import HotWeb.Components.Overlay, only: [overlay: 1]
      import HotWeb.Components.Pagination, only: [pagination: 1]
      import HotWeb.Components.PasswordField, only: [password_field: 1]
      import HotWeb.Components.Popover, only: [popover: 1, popover_trigger: 1, popover_content: 1]

      import HotWeb.Components.Progress,
        only: [progress: 1, progress_section: 1, semi_circle_progress: 1, ring_progress: 1]

      import HotWeb.Components.RadioCard, only: [radio_card: 1, radio_card_check: 3]
      import HotWeb.Components.RadioField, only: [radio_field: 1, group_radio: 1, radio_check: 3]
      import HotWeb.Components.RangeField, only: [range_field: 1]
      import HotWeb.Components.Rating, only: [rating: 1]
      import HotWeb.Components.ScrollArea, only: [scroll_area: 1]
      import HotWeb.Components.SearchField, only: [search_field: 1]
      import HotWeb.Components.Sidebar, only: [sidebar: 1]
      import HotWeb.Components.Skeleton, only: [skeleton: 1]
      import HotWeb.Components.SpeedDial, only: [speed_dial: 1]
      import HotWeb.Components.Spinner, only: [spinner: 1]
      import HotWeb.Components.Stepper, only: [stepper: 1, stepper_section: 1]
      import HotWeb.Components.Table, only: [table: 1, th: 1, tr: 1, td: 1]

      import HotWeb.Components.TableContent,
        only: [table_content: 1, content_wrapper: 1, content_item: 1]

      import HotWeb.Components.Tabs,
        only: [tabs: 1, show_tab: 2, show_tab: 3, hide_tab: 2, hide_tab: 3]

      import HotWeb.Components.TelField, only: [tel_field: 1]
      import HotWeb.Components.TextField, only: [text_field: 1]
      import HotWeb.Components.TextareaField, only: [textarea_field: 1]
      import HotWeb.Components.Timeline, only: [timeline: 1, timeline_section: 1]

      import HotWeb.Components.Toast,
        only: [
          toast: 1,
          toast_group: 1,
          show_toast: 1,
          show_toast: 2,
          hide_toast: 1,
          hide_toast: 2
        ]

      import HotWeb.Components.ToggleField, only: [toggle_field: 1, toggle_check: 2]
      import HotWeb.Components.Tooltip, only: [tooltip: 1]

      import HotWeb.Components.Typography,
        only: [
          h1: 1,
          h2: 1,
          h3: 1,
          h4: 1,
          h5: 1,
          h6: 1,
          p: 1,
          strong: 1,
          em: 1,
          dl: 1,
          dt: 1,
          dd: 1,
          figure: 1,
          figcaption: 1,
          abbr: 1,
          mark: 1,
          small: 1,
          s: 1,
          u: 1,
          cite: 1,
          del: 1
        ]

      import HotWeb.Components.UrlField, only: [url_field: 1]
      import HotWeb.Components.Video, only: [video: 1]
    end
  end
end
