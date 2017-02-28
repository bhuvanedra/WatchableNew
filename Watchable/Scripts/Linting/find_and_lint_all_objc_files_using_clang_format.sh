find ./Watchable -name "*.[h,m]" -type f -print0 | xargs -0 clang-format -i -style=file
