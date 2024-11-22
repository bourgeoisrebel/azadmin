#!/bin/bash
set -e

while [[ $# -gt 0 ]]; do
    case $1 in
    -v|--vault-name)
        VAULT_NAME="$2"
        shift # past argument
        shift # past value
        ;;
    -s|--secret-name)
        SECRET_NAME="$2"
        shift # past argument
        shift # past value
        ;;
    -*|--*)
        echo "Unknown option $1"
        exit 1
        ;;
    *)
        POSITIONAL_ARGS+=("$1") # save positional arg
        shift # past argument
        ;;
    esac
done

set -- "${POSITIONAL_ARGS[@]}" # restore positional parameters

# check ssh folder exists
SSH_FOLDER="$HOME/.ssh"
if [[ -d "$SSH_FOLDER" ]]; then
    echo '.ssh folder already exists'
else
    echo 'Creating SSH folder...'
    mkdir "$SSH_FOLDER/.ssh/"
fi

# check key exists in ssh folder
if [[ $(find "$SSH_FOLDER" -name "$SECRET_NAME") ]]
then
    echo "The key ${SECRET_NAME} was found"
else
    echo "The key ${SECRET_NAME} does not exist!"
    echo "Downloading key now..."
    az keyvault secret download \
        --vault-name "$VAULT_NAME" \
        --name "$SECRET_NAME" \
        --file "$SSH_FOLDER/$SECRET_NAME"
    echo "Key downloaded. Setting permissions..."
    chmod 600 "$SSH_FOLDER/$SECRET_NAME"
fi
