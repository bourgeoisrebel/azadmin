# azadmin - container container Azure admin tools


# docker

## Installed in this image

- Azure CLI 2.35.0
    - Azure DevOps extension
- Terraform 1.1.8
- Az Powershell Module 7.4.0 
- Helm 3.8.2
- kubectl 1.23.5

## Build
To build from docker file, navigate to directory containing docker file then:

``` docker build . ```

To pull latest version of the image:

``` docker pull azadmin ```

## To run interactively:

CLI:

``` docker run -it -v $PWD:/git azadmin bash ```

Powershell: 

``` docker run -it -v $PWD:/git azadmin pwsh ```

**Centos version deprecated**
