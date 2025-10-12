@echo off
setlocal enabledelayedexpansion

echo Deploying SG Farmers App to AWS...

REM Set default values
set AWS_REGION=eu-west-2
set PROJECT_NAME=sg-farmers-app
set ENVIRONMENT=production

REM Check prerequisites
echo Checking prerequisites...

where aws >nul 2>&1
if errorlevel 1 (
    echo Error: AWS CLI is not installed
    pause
    exit /b 1
)

where terraform >nul 2>&1
if errorlevel 1 (
    echo Error: Terraform is not installed
    pause
    exit /b 1
)

where docker >nul 2>&1
if errorlevel 1 (
    echo Error: Docker is not installed
    pause
    exit /b 1
)

REM Check AWS credentials
aws sts get-caller-identity >nul 2>&1
if errorlevel 1 (
    echo Error: AWS credentials not configured
    pause
    exit /b 1
)

echo Prerequisites check passed

REM Deploy based on argument
set DEPLOY_TYPE=%1
if "%DEPLOY_TYPE%"=="" set DEPLOY_TYPE=all

if "%DEPLOY_TYPE%"=="infrastructure" goto deploy_infra
if "%DEPLOY_TYPE%"=="images" goto build_images
if "%DEPLOY_TYPE%"=="services" goto update_services
if "%DEPLOY_TYPE%"=="frontend" goto deploy_frontend
if "%DEPLOY_TYPE%"=="all" goto deploy_all

echo Usage: deploy.bat [infrastructure^|images^|services^|frontend^|all]
pause
exit /b 1

:deploy_infra
echo Deploying infrastructure...
cd terraform
terraform init
terraform plan -out=tfplan
terraform apply tfplan
cd ..
goto end

:build_images
echo Building and pushing images...
call scripts\build-and-push.bat
goto end

:update_services
echo Updating ECS services...
aws ecs update-service --cluster %PROJECT_NAME%-cluster --service %PROJECT_NAME%-registration-api --force-new-deployment --region %AWS_REGION%
aws ecs update-service --cluster %PROJECT_NAME%-cluster --service %PROJECT_NAME%-search-api --force-new-deployment --region %AWS_REGION%
aws ecs update-service --cluster %PROJECT_NAME%-cluster --service %PROJECT_NAME%-chat-api --force-new-deployment --region %AWS_REGION%
goto end

:deploy_frontend
echo Deploying frontend...
cd services\frontend
npm install
npm run build
REM Get bucket name from Terraform output
cd ..\..\terraform
for /f "tokens=*" %%i in ('terraform output -raw frontend_bucket_name') do set BUCKET_NAME=%%i
for /f "tokens=*" %%i in ('terraform output -raw cloudfront_distribution_id') do set DISTRIBUTION_ID=%%i
cd ..\services\frontend
aws s3 sync build/ s3://%BUCKET_NAME%/ --delete
aws cloudfront create-invalidation --distribution-id %DISTRIBUTION_ID% --paths "/*"
cd ..\..
goto end

:deploy_all
call :deploy_infra
call :build_images
call :update_services
call :deploy_frontend
goto end

:end
echo Deployment completed successfully!
pause