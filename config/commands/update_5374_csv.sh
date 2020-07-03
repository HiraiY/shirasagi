#!/bin/bash
PAR_CMD=${1:-"site"}
PAR_PATH=${2:-""}

if [ $PAR_CMD != "site" ]; then
  echo "folder is only valid" 1>&2
  exit 1
fi

/bin/cp "$PAR_PATH/5374/hokubu/area_list/area_days.csv" "/var/www/kakegawa-5374/hokubu/data/area_days.csv"
/bin/cp "$PAR_PATH/5374/hokubu/category_list/description.csv" "/var/www/5374_hokubu/data/description.csv"
/bin/cp "$PAR_PATH/5374/hokubu/center_list/center.csv" "/var/www/5374_hokubu/data/center.csv"
/bin/cp "$PAR_PATH/5374/hokubu/garbage_list/target.csv" "/var/www/5374_hokubu/data/target.csv"
/bin/cp "$PAR_PATH/5374/hokubu/remark_list/remarks.csv" "/var/www/5374_hokubu/data/remarks.csv"


/bin/cp "$PAR_PATH/5374/nanbu/area_list/area_days.csv" "/var/www/kakegawa-5374/nanbu/data/area_days.csv"
/bin/cp "$PAR_PATH/5374/nanbu/category_list/description.csv" "/var/www/5374_nanbu/data/description.csv"
/bin/cp "$PAR_PATH/5374/nanbu/center_list/center.csv" "/var/www/5374_nanbu/data/center.csv"
/bin/cp "$PAR_PATH/5374/nanbu/garbage_list/target.csv" "/var/www/5374_nanbu/data/target.csv"
/bin/cp "$PAR_PATH/5374/nanbu/remark_list/remarks.csv" "/var/www/5374_nanbu/data/remarks.csv"
