# Getting variables
while getopts l:f:b: flag
do
    case "${flag}" in
        l) local=${OPTARG};;
        f) file=${OPTARG};; # Flag with file to be downloaded from server
        b) bucket=${OPTARG};; # Flag announcing the bucket to insert data into
    esac
done
# file does not exists
if [[ $local = "dev" ]]; then # Checking if manual GCS credential is needed
    echo "LOCAL DEVELOPMENT ENV!!"
    if ! [[ $(ls credentials/ | grep gcs_credential.json) ]]; then
        echo "Creating a local GCS Credential File into credentials/gcs_credential.json"
        terraform output service-credential-private >> credentials/gcs_credential.json
    else
        echo "GCS Credential File already exists."
    fi
else
    echo "NOT LOCAL DEVELOPMENT ENV"
fi

echo "Data Lake Bucket to insert data ${bucket}"
echo "File to be transfered from FTP server to DL ftp://ftp.mtps.gov.br/%2f${file}"

curl -u anonymous:anonymous "ftp://ftp.mtps.gov.br/%2f${file}" -o temp_download 
gsutil -o Credentials:gs_service_key_file=${PWD}/credentials/gcs_credential.json cp temp_download gs://${bucket}/landing_zone/${file}
rm -rf temp_download