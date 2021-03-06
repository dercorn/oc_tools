#! /bin/bash
#
# CAUTION: new file formats need to be added in three different places!
#
# (C) 2017 jw@owncloud.com - All rights reserved.
# Not for commercial use.
# 

OC_DATA_DIR=var.www.owncloud

find "$OC_DATA_DIR" -type d -iname oc-logs -print | while read -r FOLDER; do

  find "$FOLDER" -type f -print | while read -r FILE; do
    FILE_EXT=
    case $FILE in
    *.converted.tar*|*.converted.zip)
      ;;
    *.tar)
      FILE_BASE=$(basename "${FILE}" .tar)
      FILE_EXT=tar
      ;;
    *.tar.gz)
      FILE_BASE=$(basename "${FILE}" .tar.gz)
      FILE_EXT=tar.gz
      ;;
    *.tar.bz2)
      FILE_BASE=$(basename "${FILE}" .tar.bz2)
      FILE_EXT=tar.bz
      ;;
    *.tar.xz)
      FILE_BASE=$(basename "${FILE}" .tar.xz)
      FILE_EXT=tar.xz
      ;;
    *.zip)
      FILE_BASE=$(basename "${FILE}" .zip)
      FILE_EXT=zip
      ;;
    esac

    if [ -n "$FILE_EXT" ]; then
      FILE_NEW="${FOLDER}/${FILE_BASE}.converted.${FILE_EXT}"
      if [ ! -f "$FILE_NEW" ]; then 
        # FIXME: tiny-race condition here.
        :> "$FILE_NEW"
        echo "> converting ${FILE} to $FILE_NEW"

	TMPDIR="/tmp/oclog-cron-$$"
	error="$TMPDIR/.errors.txt"
	mkdir $TMPDIR
	echo > $error ""

	if [ "$FILE_EXT" = "zip" ]; then
	  (cd "$TMPDIR" && unzip /dev/stdin || echo >> $error "unzip failed") < "$FILE"
	elif [ "$FILE_EXT" = "tar" ]; then
	  (cd "$TMPDIR" && tar xf - || echo >> $error "untar $FILE_EXT failed") < "$FILE"
	elif [ "$FILE_EXT" = "tar.gz" ]; then
	  (cd "$TMPDIR" && tar zxf - || echo >> $error "untar $FILE_EXT failed") < "$FILE"
	elif [ "$FILE_EXT" = "tar.bz2" ]; then
	  (cd "$TMPDIR" && tar jxf - || echo >> $error "untar $FILE_EXT failed") < "$FILE"
	elif [ "$FILE_EXT" = "tar.xz" ]; then
	  (cd "$TMPDIR" && tar Jxf - || echo >> $error "untar $FILE_EXT failed") < "$FILE"
	else
	  echo >> "$error" "unpack $FILE_EXT not implemented"
	fi

	find "$TMPDIR" -type f -print | while read -r Target; do

	  echo "convert $Target"

	  ## (C) 2017 carlos@owncloud.com
	  
	  # Optimized the command. All seds in 1 line:
	  
	  # remove all extra backslashes \
	  #sed -i 's:\\\\\\\\:\\:g' "$Target"
 	  #sed -i 's:\\\\\\:\\:g' "$Target"
	  #sed -i 's:\\\\:\\:g' "$Target"

	  # change \" to "
	  #sed -i 's:\\":":g' "$Target"
	  # change )\ to )
	  #sed -i 's:)\\:):g' "$Target"
	  # change \/ to /
	  #sed -i 's:\\/:/:g' "$Target"
	  # add n to #0 -> n#0
	  #sed -i 's:#0:n#0:g' "$Target"
	  # separate stack trace
	  #sed -i 's:n#:\n#:g' "$Target"
	  # separating each stack trace with an extra line
	  #sed -i '-e 'G' "$Target"

	  # normal quotation
	  #sed -i 's:\\n:\n:g' "$Target"
	  #sed -i 's:\\t:\t:g' "$Target"

	  sed -i -e 's:\\\\\\\\:\\:g' -e 's:\\\\\\:\\:g' -e 's:\\\\:\\:g' -e 's:\\":":g' -e  's:)\\:):g' -e 's:\\/:/:g' -e 'G' -e 's:#0:n#0:g' -e 's:n#:\n#:g'  -e  's:\\n:\n:g' -e 's:\\t:\t:g'  "$Target"


	done

	test -s "$error" || rm -f "$error"

	if [ "$FILE_EXT" = "zip" ]; then
	  (cd "$TMPDIR" && zip -r - .) > "$FILE_NEW"
	elif [ "$FILE_EXT" = "tar" ]; then
	  tar cf - -C "$TMPDIR" . > "$FILE_NEW"
	elif [ "$FILE_EXT" = "tar.gz" ]; then
	  tar zcf - -C "$TMPDIR" . > "$FILE_NEW"
	elif [ "$FILE_EXT" = "tar.bz2" ]; then
	  tar jcf - -C "$TMPDIR" . > "$FILE_NEW"
	elif [ "$FILE_EXT" = "tar.xz" ]; then
	  tar Jcf - -C "$TMPDIR" . > "$FILE_NEW"
	else
	  echo >> $error "repack $FILE_EXT not implemented"
	fi

	if [ -e "$error" ]; then
	  echo "ERROR:"
	  cat $error
	  rm -f "$FILE_NEW"
	fi
	rm -rf "$TMPDIR"
      fi
    fi
  done
done
