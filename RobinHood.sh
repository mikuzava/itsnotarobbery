#!/bin/bash

if ! command -v dialog &>/dev/null; then
  sudo apt update &>/dev/null && sudo apt install dialog -y &>/dev/null
fi

if ! command -v jq &>/dev/null; then
  sudo apt update &>/dev/null && sudo apt install jq -y &>/dev/null
fi

exit_0() {
  clear
  exit 0
}

if [[ $# -eq 3 ]]; then
  if [ "$3" == "--force" ]; then
    force="true"
  fi
fi

# Check if node and option were passed as arguments
if [ $# -eq 2 ]; then
  node="$1"
  option="$2"
  # Check if the selected node exists in the available nodes
  nodes=$(curl -s https://sh.doubletop.io/available.json | jq -r '.[].node')
  if [[ ! $nodes =~ (^|[[:space:]])$node($|[[:space:]]) ]]; then
    dialog --title "Error" --msgbox "The selected node does not exist." 0 0
    exit_0
  else
    # Check if the selected option exists for the selected node
    options=$(curl -s https://sh.doubletop.io/available.json | jq -r ".[] | select(.node == \"$node\") | .options[]")
    if [[ ! $options =~ (^|[[:space:]])$option($|[[:space:]]) ]]; then
      dialog --title "Error" --msgbox "The selected option does not exist for the selected node." 0 0
      exit_0
    fi
  fi
elif [ $# -eq 1 ]; then
  node="$1"
  # Check if the selected node exists in the available nodes
  nodes=$(curl -s https://sh.doubletop.io/available.json | jq -r '.[].node')
  if [[ ! $nodes =~ (^|[[:space:]])$node($|[[:space:]]) ]]; then
    dialog --title "Error" --msgbox "The selected node does not exist." 0 0
    exit_0
  else
    # Check if the user selected an option
    if [ -z "$2" ]; then
      dialog --title "Error" --msgbox "Please enter option for this node." 0 0
      exit_0
    fi
  fi
fi

# Function to show the available nodes
show_nodes() {
  # Get the available nodes from the URL
  nodes=$(curl -s https://sh.doubletop.io/available.json)
  # Check if the nodes were loaded successfully
  if [ $? -ne 0 ]; then
    dialog --title "Error" --msgbox "Error loading the available nodes." 0 0
    return 1
  fi
  # Parse the JSON and get the node names
  names=$(echo "$nodes" | jq -r '.[].node')
  # Create an array with the node names
  names_array=()
  for node in $names; do
    names_array+=("$node" "")
  done
  # Show a menu with the node names
  node=$(dialog --stdout --menu "Select a node:" 0 0 0 "${names_array[@]}")
  # Return the selected node
  echo "$node"
}

# Function to show the available options for a node
show_options() {
  # Get the options for the selected node from the URL
  options=$(curl -s https://sh.doubletop.io/available.json | jq -r ".[] | select(.node == \"$1\") | .options[]")
  # Check if the options were loaded successfully
  if [ $? -ne 0 ]; then
    dialog --title "Error" --msgbox "Error loading the available options for $1." 0 0
    return 1
  fi
  # Create an array with the options
  options_array=()
  for option in $options; do
    options_array+=("$option" "")
  done
  # Show a menu with the options
  option=$(dialog --stdout --menu "Select an option for $1:" 0 0 0 "${options_array[@]}")
  # Return the selected option
  echo "$option"
}

if [[ $force == "true" ]]; then
  node="$1"
  option="$2"
  # Execute the installation script force
  script_link="https://raw.githubusercontent.com/DOUBLE-TOP/guides/main/$node/setup.sh"
  . <(wget -qO- $script_link) "$node" "$option" "--force"
else
  if [ $# -eq 2 ]; then
    node="$1"
    option="$2"
  else
    # Show the main menu
    dialog --colors --title "Node Installer" --msgbox "\nWelcome to DOUBLETOP universal installer tool" 0 0
    # Show the nodes menu
    node=$(show_nodes)
    if [ -z "$node" ]; then
      exit 0
    fi
    # Show the options menu
    option=$(show_options "$node")
    if [ -z "$option" ]; then
      exit 0
    fi
  fi
  # Execute the installation script
  script_link="https://raw.githubusercontent.com/DOUBLE-TOP/guides/main/$node/setup.sh"
  . <(wget -qO- $script_link) "$node" "$option"
fi


clear
