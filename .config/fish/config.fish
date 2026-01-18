fastfetch
if status is-interactive
    # Commands to run in interactive sessions can go here
end

set fish_greeting
set -x LANG en_US.UTF-8
set -x LC_ALL en_US.UTF-8
set -gx PATH $HOME/.local/bin $PATH
set -gx MOZ_DISABLE_RDD_SANDBOX 1
set -gx QT_QPA_PLATFORMTHEME qt6ct-kde
set -gx PATH $HOME/.cargo/bin $PATH
fish_add_path ~/.local/bin

