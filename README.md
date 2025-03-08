# lambda-toys-api-infra

# Go to pwsh cmdline to the folder path where core.bicep is located and run deployment

# use az interactive

# create RG 
az>> group create --name "lambda-api-dev" --location centralindia

# Run Deployment
az>> deployment group create -g lambda-api-dev --template-file infrastructure/core.bicep
Please provide string value for 'location' (? for help): centralindia
Please provide string value for 'prefix' (? for help): lambd-dev
Name    State      Timestamp                         Mode         ResourceGroup
------  ---------  --------------------------------  -----------  ---------------
core    Succeeded  2025-03-07T18:33:13.504098+00:00  Incremental  lambda-api-dev

# check in portal

az>> deployment group create -g lambda-api-dev --template-file infrastructure/core.bicep --parameters @configurations/dev.json
Name    State      Timestamp                         Mode         ResourceGroup
------  ---------  --------------------------------  -----------  ---------------
core    Succeeded  2025-03-07T18:40:11.087460+00:00  Incremental  lambda-api-dev
az>> deployment group create -g lambda-api-dev --template-file infrastructure/core.bicep --parameters configurations/dev.bicepparam
Name    State      Timestamp                         Mode         ResourceGroup
------  ---------  --------------------------------  -----------  ---------------
core    Succeeded  2025-03-07T18:41:43.247031+00:00  Incremental  lambda-api-dev
az>> deployment group create -g lambda-api-dev --parameters configurations/dev.bicepparam
Name         State      Timestamp                         Mode         ResourceGroup
-----------  ---------  --------------------------------  -----------  ---------------
deployment1  Succeeded  2025-03-07T18:44:32.107814+00:00  Incremental  lambda-api-dev