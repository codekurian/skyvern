#!/bin/bash

USE_STANDALONE_POSTGRES=true

for arg in "$@"; do
    if [ "$arg" == "--standalone-postgres" ]; then
        USE_STANDALONE_POSTGRES=true
    fi
done

# Call function to send telemetry event
log_event() {
    if [ -n $1 ]; then
        poetry run python skyvern/analytics.py $1
    fi
}

# Function to check if a command exists
command_exists() {
    command -v "$1" &> /dev/null
}

ensure_required_commands() {
    # Ensure required commands are available
    for cmd in poetry npm; do
        if ! command_exists "$cmd"; then
            echo "Error: $cmd is not installed." >&2
            exit 1
        fi
    done
    # Only check Docker if not using standalone Postgres
    if [ "$USE_STANDALONE_POSTGRES" != true ]; then
        if ! command_exists docker || ! docker info > /dev/null 2>&1; then
            echo "Docker is not running. Please start Docker and try again."
            exit 1
        fi
    fi
}

# Function to update or add environment variable in .env file
update_or_add_env_var() {
    local key=$1
    local value=$2
    if grep -q "^$key=" .env; then
        # Update existing variable
        sed -i.bak "s/^$key=.*/$key=$value/" .env && rm -f .env.bak
    else
        # Add new variable
        echo "$key=$value" >> .env
    fi
}

# Function to set up LLM provider environment variables
setup_llm_providers() {
    echo "Configuring Large Language Model (LLM) Providers..."
    echo "Note: All information provided here will be stored only on your local machine."
    local model_options=()

    # OpenAI Configuration
    echo "To enable OpenAI, you must have an OpenAI API key."
    read -p "Do you want to enable OpenAI (y/n)? " enable_openai
    if [[ "$enable_openai" == "y" ]]; then
        read -p "Enter your OpenAI API key: " openai_api_key
        if [ -z "$openai_api_key" ]; then
            echo "Error: OpenAI API key is required."
            echo "OpenAI will not be enabled."
        else
            update_or_add_env_var "OPENAI_API_KEY" "$openai_api_key"
            update_or_add_env_var "ENABLE_OPENAI" "true"
            model_options+=(
                "OPENAI_GPT4_1"
                "OPENAI_GPT4_1_MINI"
                "OPENAI_GPT4_1_NANO"
                "OPENAI_GPT4O"
                "OPENAI_O4_MINI"
                "OPENAI_O3"
            )
        fi
    else
        update_or_add_env_var "ENABLE_OPENAI" "false"
    fi

    # Anthropic Configuration
    echo "To enable Anthropic, you must have an Anthropic API key."
    read -p "Do you want to enable Anthropic (y/n)? " enable_anthropic
    if [[ "$enable_anthropic" == "y" ]]; then
        read -p "Enter your Anthropic API key: " anthropic_api_key
        if [ -z "$anthropic_api_key" ]; then
            echo "Error: Anthropic API key is required."
            echo "Anthropic will not be enabled."
        else
            update_or_add_env_var "ANTHROPIC_API_KEY" "$anthropic_api_key"
            update_or_add_env_var "ENABLE_ANTHROPIC" "true"
            model_options+=(
                "ANTHROPIC_CLAUDE3.5_SONNET"
                "ANTHROPIC_CLAUDE3.7_SONNET"
            )
        fi
    else
        update_or_add_env_var "ENABLE_ANTHROPIC" "false"
    fi

    # Azure Configuration
    echo "To enable Azure, you must have an Azure deployment name, API key, base URL, and API version."
    read -p "Do you want to enable Azure (y/n)? " enable_azure
    if [[ "$enable_azure" == "y" ]]; then
        read -p "Enter your Azure deployment name: " azure_deployment
        read -p "Enter your Azure API key: " azure_api_key
        read -p "Enter your Azure API base URL: " azure_api_base
        read -p "Enter your Azure API version: " azure_api_version
        if [ -z "$azure_deployment" ] || [ -z "$azure_api_key" ] || [ -z "$azure_api_base" ] || [ -z "$azure_api_version" ]; then
            echo "Error: All Azure fields must be populated."
            echo "Azure will not be enabled."
        else
            update_or_add_env_var "AZURE_DEPLOYMENT" "$azure_deployment"
            update_or_add_env_var "AZURE_API_KEY" "$azure_api_key"
            update_or_add_env_var "AZURE_API_BASE" "$azure_api_base"
            update_or_add_env_var "AZURE_API_VERSION" "$azure_api_version"
            update_or_add_env_var "ENABLE_AZURE" "true"
            model_options+=(
                "AZURE_OPENAI_GPT4O"
            )
        fi
    else
        update_or_add_env_var "ENABLE_AZURE" "false"
    fi

    #Gemini Configuartion
    echo "To enable Gemini, you must have an Gemini API key."
    read -p "Do you want to enable Gemini (y/n)? " enable_gemini
    if [[ "$enable_gemini" == "y" ]]; then
        read -p "Enter your Gemini API key: " gemini_api_key
        if [ -z "$gemini_api_key" ]; then
            echo "Error: Gemini API key is required."
            echo "Gemini will not be enabled."
        else
            update_or_add_env_var "GEMINI_API_KEY" "$gemini_api_key"
            update_or_add_env_var "ENABLE_GEMINI" "true"
            model_options+=(
                "GEMINI_FLASH_2_0"
                "GEMINI_FLASH_2_0_LITE"
                "GEMINI_2.5_PRO_PREVIEW_03_25"
                "GEMINI_2.5_PRO_EXP_03_25"
            )
        fi
    else
        update_or_add_env_var "ENABLE_GEMINI" "false"
    fi

    # Novita AI Configuration
    echo "To enable Novita AI, you must have an Novita AI API key."
    read -p "Do you want to enable Novita AI (y/n)? " enable_novita
    if [[ "$enable_novita" == "y" ]]; then
        read -p "Enter your Novita AI API key: " novita_api_key
        if [ -z "$novita_api_key" ]; then
            echo "Error: Novita AI API key is required."
            echo "Novita AI will not be enabled."
        else
            update_or_add_env_var "NOVITA_API_KEY" "$novita_api_key"
            update_or_add_env_var "ENABLE_NOVITA" "true"
            model_options+=(
                "NOVITA_DEEPSEEK_R1"
                "NOVITA_DEEPSEEK_V3"
                "NOVITA_LLAMA_3_3_70B"
                "NOVITA_LLAMA_3_2_1B"
                "NOVITA_LLAMA_3_2_3B"
                "NOVITA_LLAMA_3_2_11B_VISION"
                "NOVITA_LLAMA_3_1_8B"
                "NOVITA_LLAMA_3_1_70B"
                "NOVITA_LLAMA_3_1_405B"
                "NOVITA_LLAMA_3_8B"
                "NOVITA_LLAMA_3_70B"
            )
        fi
    else
        update_or_add_env_var "ENABLE_NOVITA" "false"
    fi

    # OpenAI Compatible Configuration
    echo "To enable an OpenAI-compatible provider, you must have a model name, API key, and API base URL."
    read -p "Do you want to enable an OpenAI-compatible provider (y/n)? " enable_openai_compatible
    if [[ "$enable_openai_compatible" == "y" ]]; then
        read -p "Enter the model name (e.g., 'yi-34b', 'mistral-large'): " openai_compatible_model_name
        read -p "Enter your API key: " openai_compatible_api_key
        read -p "Enter the API base URL (e.g., 'https://api.together.xyz/v1'): " openai_compatible_api_base
        read -p "Does this model support vision (y/n)? " openai_compatible_vision
        
        if [ -z "$openai_compatible_model_name" ] || [ -z "$openai_compatible_api_key" ] || [ -z "$openai_compatible_api_base" ]; then
            echo "Error: All required fields must be populated."
            echo "OpenAI-compatible provider will not be enabled."
        else
            update_or_add_env_var "OPENAI_COMPATIBLE_MODEL_NAME" "$openai_compatible_model_name"
            update_or_add_env_var "OPENAI_COMPATIBLE_API_KEY" "$openai_compatible_api_key"
            update_or_add_env_var "OPENAI_COMPATIBLE_API_BASE" "$openai_compatible_api_base"
            
            # Set vision support
            if [[ "$openai_compatible_vision" == "y" ]]; then
                update_or_add_env_var "OPENAI_COMPATIBLE_SUPPORTS_VISION" "true"
            else
                update_or_add_env_var "OPENAI_COMPATIBLE_SUPPORTS_VISION" "false"
            fi

            update_or_add_env_var "ENABLE_OPENAI_COMPATIBLE" "true"
            model_options+=(
                "OPENAI_COMPATIBLE"
            )
        fi
    else
        update_or_add_env_var "ENABLE_OPENAI_COMPATIBLE" "false"
    fi

    # Model Selection
    if [ ${#model_options[@]} -eq 0 ]; then
        echo "No LLM providers enabled. You won't be able to run Skyvern unless you enable at least one provider. You can re-run this script to enable providers or manually update the .env file."
    else
        echo "Available LLM models based on your selections:"
        for i in "${!model_options[@]}"; do
            echo "$((i+1)). ${model_options[$i]}"
        done
        read -p "Choose a model by number (e.g., 1 for ${model_options[0]}): " model_choice
        chosen_model=${model_options[$((model_choice-1))]}
        echo "Chosen LLM Model: $chosen_model"
        update_or_add_env_var "LLM_KEY" "$chosen_model"
    fi

    echo "LLM provider configurations updated in .env."
}


# Function to initialize .env file
initialize_env_file() {
    if [ -f ".env" ]; then
        echo ".env file already exists, skipping initialization."
        read -p "Do you want to go through LLM provider setup again (y/n)? " redo_llm_setup
        if [[ "$redo_llm_setup" == "y" ]]; then
            setup_llm_providers
        fi
        return
    fi

    echo "Initializing .env file..."
    cp .env.example .env
    setup_llm_providers

    # Ask for email or generate UUID
    read -p "Please enter your email for analytics (press enter to skip): " analytics_id
    if [ -z "$analytics_id" ]; then
        analytics_id=$(uuidgen)
    fi
    update_or_add_env_var "ANALYTICS_ID" "$analytics_id"
    echo ".env file has been initialized."
}

initialize_frontend_env_file() {
    if [ -f "skyvern-frontend/.env" ]; then
        echo "skyvern-frontend/.env file already exists, skipping initialization."
        return
    fi

    echo "Initializing skyvern-frontend/.env file..."
    cp skyvern-frontend/.env.example skyvern-frontend/.env
    echo "skyvern-frontend/.env file has been initialized."
}

# Function to remove Poetry environment
remove_poetry_env() {
    local env_path
    env_path=$(poetry env info --path)
    if [ -d "$env_path" ]; then
        rm -rf "$env_path"
        echo "Removed the poetry environment at $env_path."
    else
        echo "No poetry environment found."
    fi
}

# Choose python version
choose_python_version_or_fail() {
  # https://github.com/python-poetry/poetry/issues/2117
  # Py --list-paths 
    # This will output which paths are being used for Python 3.11
  # Windows users need to poetry env use {{ Py --list-paths with 3.11}}
  poetry env use python3.13 || { echo "Error: Python 3.13 is not installed. Please install Python 3.13 and try again."; exit 1; }
}


# Function to install dependencies
install_dependencies() {
    poetry install
    echo "Installing frontend dependencies"
    cd skyvern-frontend
    npm install --silent
    cd ..
    echo "Frontend dependencies installed."
}

activate_poetry_env() {
    source "$(poetry env info --path)/bin/activate"
}

install_dependencies_after_poetry_env() {
    echo "Installing playwright dependencies..."
    playwright install
}

# Function to set the PostgreSQL connection string
set_postgres_connection_string() {
    local conn_str="postgresql+psycopg://skyvern:skyvern@localhost:5432/skyvern"
    update_or_add_env_var "DATABASE_STRING" "$conn_str"
    echo "DATABASE_STRING set to $conn_str"
}

# Function to setup PostgreSQL
setup_postgresql() {
    echo "Checking for existing PostgreSQL installation..."

    if [ "$USE_STANDALONE_POSTGRES" = true ]; then
        # Install PostgreSQL via Homebrew if not present
        if ! command_exists psql; then
            echo "psql not found. Installing PostgreSQL 14 via Homebrew..."
            brew install postgresql@14
            brew services start postgresql@14
            # Add Homebrew's bin to PATH for this session if needed
            export PATH="/usr/local/opt/postgresql@14/bin:$PATH"
            sleep 5
        else
            # Ensure the service is started
            brew services start postgresql@14
        fi
    fi

    if command_exists psql && pg_isready > /dev/null 2>&1; then
        echo "PostgreSQL is already running locally."
        # Check if the database and user exist
        if psql -U skyvern -d skyvern -c '\q' 2>/dev/null; then
            echo "Database and user exist. Skipping creation."
            set_postgres_connection_string
            return 0
        else
            echo "Database or user does not exist. Creating them..."
            createuser skyvern || true
            createdb skyvern -O skyvern || true
            set_postgres_connection_string
            return 0
        fi
    fi

    if [ "$USE_STANDALONE_POSTGRES" = true ]; then
        echo "Standalone Postgres flag is set, but no running local Postgres was found. Please start Postgres (e.g., with 'brew services start postgresql@14') and rerun this script."
        exit 1
    fi

    # Check if Docker is installed and running
    if ! command_exists docker || ! docker info > /dev/null 2>&1; then
        echo "Docker is not running or not installed. Please install or start Docker and try again."
        exit 1
    fi

    # Check if PostgreSQL is already running in a Docker container
    if docker ps | grep -q postgresql-container; then
        echo "PostgreSQL is already running in a Docker container."
    else 
        # Attempt to install and start PostgreSQL using Docker
        echo "Attempting to install PostgreSQL via Docker..."
        docker run --name postgresql-container -e POSTGRES_HOST_AUTH_METHOD=trust -d -p 5432:5432 postgres:14
        echo "PostgreSQL has been installed and started using Docker."

        # Wait for PostgreSQL to start
        echo "Waiting for PostgreSQL to start..."
        sleep 20  # Adjust sleep time as necessary
    fi

    # Assuming docker exec works directly since we've checked Docker's status before
    if docker exec postgresql-container psql -U postgres -c "\\du" | grep -q skyvern; then
        echo "Database user exists."
    else
        echo "Creating database user..."
        docker exec postgresql-container createuser -U postgres skyvern
    fi

    if docker exec postgresql-container psql -U postgres -lqt | cut -d \| -f 1 | grep -qw skyvern; then
        echo "Database exists."
    else
        echo "Creating database..."
        docker exec postgresql-container createdb -U postgres skyvern -O skyvern
        echo "Database and user created successfully."
    fi
    set_postgres_connection_string
}

# Function to run Alembic upgrade
run_alembic_upgrade() {
    echo "Running Alembic upgrade..."
    alembic upgrade head
}

# Function to create organization and API token
create_organization() {
    echo "Creating organization and API token..."
    local org_output api_token
    org_output=$(poetry run python scripts/create_organization.py Skyvern-Open-Source)
    api_token=$(echo "$org_output" | awk '/token=/{gsub(/.*token='\''|'\''.*/, ""); print}')

    # Ensure .streamlit directory exists
    mkdir -p .streamlit

    # Check if secrets.toml exists and back it up
    if [ -f ".streamlit/secrets.toml" ]; then
        mv .streamlit/secrets.toml .streamlit/secrets.backup.toml
        echo "Existing secrets.toml file backed up as secrets.backup.toml"
    fi

    # Update the secrets-open-source.toml file
    echo -e "[skyvern]\nconfigs = [\n    {\"env\" = \"local\", \"host\" = \"http://127.0.0.1:8000/api/v1\", \"orgs\" = [{name=\"Skyvern\", cred=\"$api_token\"}]}\n]" > .streamlit/secrets.toml
    echo ".streamlit/secrets.toml file updated with organization details."

    # Check if skyvern-frontend/.env exists and back it up
    # This is redundant for first time set up but useful for subsequent runs
    if [ -f "skyvern-frontend/.env" ]; then
        mv skyvern-frontend/.env skyvern-frontend/.env.backup
        echo "Existing skyvern-frontend/.env file backed up as skyvern-frontend/.env.backup"
        cp skyvern-frontend/.env.example skyvern-frontend/.env
    fi

    # Update the skyvern-frontend/.env file
    # sed wants a backup file extension, and providing empty string doesn't work on all platforms
    sed -i".old" -e "s/YOUR_API_KEY/$api_token/g" skyvern-frontend/.env
    echo "skyvern-frontend/.env file updated with API token."
}

# Main function
main() {
    ensure_required_commands
    initialize_env_file
    initialize_frontend_env_file
    choose_python_version_or_fail
    remove_poetry_env
    install_dependencies
    setup_postgresql
    activate_poetry_env
    install_dependencies_after_poetry_env
    run_alembic_upgrade
    create_organization
    log_event "skyvern-oss-setup-complete"
    echo "Setup completed successfully."
}

# Execute main function
main
