find ../ -name "*.lua" | xargs sed -i -r 's#[ \t]+$##g'

find ../ -name "*.sh" | xargs sed -i -r 's#[ \t]+$##g'

find ../ -name "*.md" | xargs sed -i -r 's#[ \t]+$##g'
