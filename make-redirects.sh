#!/usr/bin/env bash

BASE_URL=https://specs.amwa.tv
REDIRECTS_DIR=redirects

declare -A external_spec=(
    [ms-01]="https://e6cfd1ba-033d-44fd-8f16-0027ec40a7b2.filesusr.com/ugd/f66d69_cea9a4c10d834b819fcd3c5c66974dbb.pdf"
    [ms-02]="https://e6cfd1ba-033d-44fd-8f16-0027ec40a7b2.filesusr.com/ugd/f66d69_945288a766324109896fb0a5e5ac04c8.pdf"
    [ms-03]="https://e6cfd1ba-033d-44fd-8f16-0027ec40a7b2.filesusr.com/ugd/f66d69_b73906b95ec84be8a3a83df0279035cd.pdf"
)

function add_top_redirect {
    id=$1
    cat <<EOF > $REDIRECTS_DIR/$id.md
---
redirect_from:
  - "/$id/"
  - "/${id^^}/"
  - "/${id//-/}/"

redirect_to: "$BASE_URL/$id"
---
EOF
}

function add_version_redirect {
    id=$1
    tree=$2 # e.g. tags/v1.0 or branches/v1.0.x
    version=${tree#*/}
    [ ! -d $REDIRECTS_DIR/$id ] && mkdir $REDIRECTS_DIR/$id
    cat <<EOF > $REDIRECTS_DIR/$id/$version.md
---
redirect_from:
  - "/$id/$version/"
  - "/${id^^}/$version/"
  - "/${id//-/}/$version/"

redirect_to: "$BASE_URL/$id/$tree"
---
EOF
}

function add_external_redirect {
    id=$1
    href=$2
    echo "$id -> $href"
    cat <<EOF > $REDIRECTS_DIR/$id.md
---
redirect_from:
  - "/$id/"
  - "/${id^^}/"
  - "/${id//-/}/"

redirect_to: "$href"
---
EOF
}

rm -r $REDIRECTS_DIR
mkdir $REDIRECTS_DIR

for id_upper in $(wget -O- -q $BASE_URL/nmos/spec_list.json | jq -r '.[]') NMOS NMOS-TESTING; do 
    id="${id_upper,,}"

    echo "Adding redirects for $id"

    add_top_redirect "$id"

    # Find names of branches and tags from links on repo's main doc page
    for branch in $(curl -s $BASE_URL/$id/ | awk -F '[<> ]' '($5 ~ "href=\"branches") {print $6}'); do
        add_version_redirect $id branches/$branch
    done
    for tag in $(curl -s $BASE_URL/$id/ | awk -F '[<> ]' '($5 ~ "href=\"tags") {print $6}'); do
        add_version_redirect $id tags/$tag
    done
done

# Specs served elsewhere
for id in "${!external_spec[@]}"; do
    href=${external_spec[$id]}
    add_external_redirect $id $href
done
