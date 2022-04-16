# How to

- create a copy of `episode-s01e01.example.env` and change all variables
- execute `./marmita_uploader.sh episode-s01e01.example.env` (this is very interactive. Always ask before executing stuff)


## Features

- update rss feed
- generate thumbnail
- upload audio file
- render and upload video to youtube

detailed:
- creates a thumbnail image
  - from a base template (PNG image data, 3000 x 3000 - size matters!),
  - write the title on top of it
  - you may test it with `python create_thumbnail.py <source_image> <dest_image> <dest_image_small> <text>` (after `. env/bin/activate`)
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

- make sure python3 and virtualenv is installed

```
python3 -m virtualenv -p "$(which python3)" env
. env/bin/activate
pip install -r requirements.txt
```

# Dependencies

- jq (apt install jq)
- youtube-upload (https://github.com/tokland/youtube-upload)
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
