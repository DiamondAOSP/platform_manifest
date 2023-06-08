#!/usr/bin/env bash

SUBMODULE_PATH="$PWD/GrapheneOS"

TRACKED_BRANCH=$(git rev-parse --abbrev-ref --symbolic-full-name '@{u}' 2>/dev/null || git rev-parse --abbrev-ref HEAD)
echo "Branch: $TRACKED_BRANCH"

if [[ $TRACKED_BRANCH =~ ^.+-(.+)$ ]]; then
  SPECIAL_BRANCH=${BASH_REMATCH[1]}
  echo "Special branch: $SPECIAL_BRANCH"
fi

git -C "$SUBMODULE_PATH" fetch --tags

function find_latest_tag {
  remote_tags=$(git -C "$SUBMODULE_PATH" ls-remote -q --tags --sort=-taggerdate)
  while IFS=$'\t' read -r -a fields; do
    # Extract the tag name from the second field (refs/tags/...)
    tag=${fields[1]#refs/tags/}

    # Ignore annotated tags
    if [[ $tag == *'^{}' ]]; then
      continue
    fi

    # Parse the date and branch from the tag name
    if [[ $tag =~ ^([0-9]{8})([0-9]{2})(-(.*))?$ ]]; then
      date=${BASH_REMATCH[1]}
      revision=${BASH_REMATCH[2]}
      branch=${BASH_REMATCH[4]}

      if [[ $branch == "$SPECIAL_BRANCH" ]]; then
        echo "Found $tag"
        TAG=$tag
        return
      fi
    fi
  done <<<"$remote_tags"

  echo "No tag found"
  exit 1
}

if [[ -z "$TAG" ]]; then
  echo "No TAG specified, looking for latest"
  find_latest_tag
fi

echo Checking out "$TAG"
git -C "$SUBMODULE_PATH" checkout "$TAG"

sed -i -E -e "s/(\[GrapheneOS \`).*(\`\])/\1$TAG\2/" -e "s/(\(https:\/\/grapheneos\.org\/releases#).*(\))/\1${TAG%-*}\2/" README.md
