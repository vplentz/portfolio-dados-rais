# Getting variables
while getopts l:f:b: flag
do
    case "${flag}" in
        l) local=${OPTARG};;
        f) file=${OPTARG};; # Flag with file to be downloaded from server
        b) bucket=${OPTARG};; # Flag announcing the bucket to insert data into
    esac
done

curl -u anonymous:anonymous "ftp://ftp.mtps.gov.br/%2f${file}" -o temp_download 


# file does not exists
if [[ $local = "dev" ]]; then # Checking if manual GCS credential is needed
    echo "LOCAL DEVELOPMENT ENV!!"
    if ! [[ $(ls credentials/ | grep gcs_credential.json) ]]; then
        echo "Creating a local GCS Credential File into credentials/gcs_credential.json"
        terraform -chdir=$PWD/../../terraform/dl_gcs/ output service_credential_private >> credentials/gcs_credential.json
    else
        echo "GCS Credential File already exists."
    fi
else
    echo "NOT LOCAL DEVELOPMENT ENV"
fi

echo "Activating gcloud with credentials"
gcloud auth activate-service-account --key-file=credentials/gcs_credential.json

gsutil cp temp_download gs://${bucket}/landing_zone/${file}

echo "Data Lake Bucket to insert data ${bucket}"
echo "File to be transfered from FTP server to DL ftp://ftp.mtps.gov.br/%2f${file}"
rm -rf temp_download