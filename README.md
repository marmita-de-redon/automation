# How to

- change all variables in `marmita-form.sh`
- execute `./marmita_uploader.sh` (this is very interactive. Always ask before executing stuff)


## Features

- update rss feed
- generate thumbnail
- upload audio file
- render and upload video to youtube

detailed:
- creates a thumbnail image 
  - from a base template (png), 
  - write the title on top of it
  - you may test it with `python create_thumbnail.py`...
- uploads to archive.org
  - audio file
  - thumbnails (better quality)
- render video (still thumbnail with audio)
  - 480p, 1fps
- uploads video to youtube
- update website and rss feed
  - create the episode/post markdown
  - commit and push to repository
  - auto deploy website using github actions (configures on the website repo)

# Run locally

- make sure python is installed
- install selenium browser drivers (only Firefox was tested, so it is the recommended one)

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

## Oysttyer

First time run:
```
perl oysttyer/oysttyer.pl -keyf=./.oysttyerkey -rc=$(pwd)/.oysttyerrc -oauthwizard
``` 
