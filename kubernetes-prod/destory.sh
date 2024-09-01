set -o allexport
source .source
TF_VAR_folder_id=$YC_FOLDER_ID
tofu destroy -input=false  -compact-warnings -auto-approve
rm -rf out/*



