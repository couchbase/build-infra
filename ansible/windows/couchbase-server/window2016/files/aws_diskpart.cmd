if exist d:\ (
    echo "Disk already partitioned" >> C:\Temp\aws_diskpart.log
) else (
    diskpart /s C:\Temp\aws_diskpart.txt >> C:\Temp\aws_diskpart.log
)
