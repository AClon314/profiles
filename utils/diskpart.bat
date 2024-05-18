:: shift + f10
diskpart
select disk 0
clean
convert gpt
create partition efi size=50
format quick fs=fat32 label="System"
assign letter="S"
create partition primary
format quick fs=ntfs label="Windows"
assign letter="C"
exit