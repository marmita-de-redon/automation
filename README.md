# Run locally

- make sure python is installed

```
virtualenv -p "$(which python3)" env
. env/bin/activate
pip install -r requirements.dev.txt
``` 

# Dependencies

- jq (apt install jq)
- shoogle (pip install shoogle)
- ia (read bellow)

## install ia (internet archive)
```
curl -LO https://archive.org/download/ia-pex/ia
chmod +x ia
./ia configure #login
``` 