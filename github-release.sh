#!/bin/sh

# This script accepts the following parameters:
#
# * owner
# * repo
# * filename
# * github_api_token
# * content_type
#
# Script to upload a release asset using the GitHub API v3.
#
# Execution Example:
#
# github-release.sh github_api_token=TOKEN owner=… repo=… filename=… content_type=…
#

# Check dependencies.
set -e
xargs=$(which gxargs || which xargs)

# Validate settings.
[ "$TRACE" ] && set -x

CONFIG=$@

for line in $CONFIG; do
  eval "$line"
done


# Define variables
GH_API="https://api.github.com"
GH_REPO="$GH_API/repos/$owner/$repo"
GH_RELEASES="$GH_REPO/releases"

AUTH="Authorization: token $github_api_token"

# get all releases from GitHub
GH_REPO_RELEASES=$(curl -X GET -sH "$AUTH" $GH_RELEASES)
echo "GITHUB REPO RELEASES"
echo $GH_REPO_RELEASES
echo "---------"

# get hash of the last commit
GIT_COMMIT=$(git log --format="%H" -n 1)

# write tags of the last commit into a file
GIT_TAGS=$(git tag --contains $GIT_COMMIT)

# loop commit tags
while read -r tag; do
    echo "Tag: $tag"
    
    # check if commit tag does exist as github release | if it is the case, take the release id, otherwise empty string
    check_tag=$(echo "$GH_REPO_RELEASES" | jq '.[] | select(.tag_name == "'$tag'") | .id')

    # check if release id does not exist
    if [ "$check_tag" == "" ]
    then
        echo "New Tag: $tag"

        # create new github release
        post_body='{"tag_name": "'$tag'","target_commitish": "master","name": "'$tag'","body": "","draft": false,"prerelease": false}'
        release_reponse=$(curl -X POST -sH "$AUTH" -H "Content-Type: application/json" -d "$post_body" $GH_RELEASES)
        echo "Create GitHub Release:"
        echo "$release_reponse"
        echo "---------"

        # append asset to github release
        id=$(echo $release_reponse | jq '.id')
        name=$(basename $filename)
        GH_ASSET="https://uploads.github.com/repos/$owner/$repo/releases/$id/assets?name=$name"
        echo "$GH_ASSET"
        asset_response=$(curl -X POST --data-binary @"$filename" -sH "$AUTH" -H "Content-Type: $content_type" $GH_ASSET)

        echo "Append asset:"
        echo "$asset_response"
        echo "---------"
    fi

done <<< "$GIT_TAGS"
