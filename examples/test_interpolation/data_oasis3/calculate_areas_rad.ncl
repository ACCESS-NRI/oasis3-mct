load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"

begin

; Recalculation of the areas.nc in radians**2 for regular grids
dp_conv=3.14159265358979323846/180.
diri="./"
diro="./"
filei_grids="grids.nc"
filei_areas="areas.nc"
fileo_areas="areas_rad.nc"

fi1=addfile(diri+filei_grids, "r")
fi2=addfile(diri+filei_areas, "r")
fo1=addfile(diro+fileo_areas, "c")


lon_ssea=fi1->$"ssea.lon"$
lat_ssea=fi1->$"ssea.lat"$
clo_ssea=fi1->$"ssea.clo"$
cla_ssea=fi1->$"ssea.cla"$
lon_bggd=fi1->$"bggd.lon"$
lat_bggd=fi1->$"bggd.lat"$
clo_bggd=fi1->$"bggd.clo"$
cla_bggd=fi1->$"bggd.cla"$
srf_nogt=fi2->$"nogt.srf"$
srf_torc=fi2->$"torc.srf"$
srf_icos=fi2->$"icos.srf"$

;++++++++++
nlat=dimsizes(lon_ssea(:,0))
nlon=dimsizes(lon_ssea(0,:))
print(nlon)
print(nlat)
printVarSummary(lon_ssea)
printVarSummary(lat_ssea)
printVarSummary(clo_ssea)
printVarSummary(cla_ssea)
srf_rad:=new((/nlat,nlon/),double)
  
do i=0,nlon-1
   do j=0,nlat-1
       srf_rad(j,i) = (clo_ssea(1,j,i)*dp_conv-clo_ssea(0,j,i)*dp_conv)* (sin(cla_ssea(3,j,i)*dp_conv) - sin(cla_ssea(0,j,i)*dp_conv))
    end do	  
end do	   

x_ssea=nlat
y_ssea=nlon
srf_rad!0="y_ssea"
srf_rad!1="x_ssea"

printVarSummary(srf_rad)

fo1->$"ssea.srf"$=srf_rad

;++++++++++
nlat=dimsizes(lon_bggd(:,0))
nlon=dimsizes(lon_bggd(0,:))
print(nlon)
print(nlat)
printVarSummary(lon_bggd)
printVarSummary(lat_bggd)
printVarSummary(clo_bggd)
printVarSummary(cla_bggd)
srf_rad:=new((/nlat,nlon/),double)
  
do i=0,nlon-1
   do j=0,nlat-1
       srf_rad(j,i) = (clo_bggd(1,j,i)*dp_conv-clo_bggd(0,j,i)*dp_conv)* (sin(cla_bggd(3,j,i)*dp_conv) - sin(cla_bggd(0,j,i)*dp_conv))
    end do	  
end do	   

x_bggd=nlat
y_bggd=nlon
srf_rad!0="y_bggd"
srf_rad!1="x_bggd"

printVarSummary(srf_rad)

fo1->$"bggd.srf"$=srf_rad

;++++++++++++++++++++++++++++++++
Rnogt=6371229.
nlat=dimsizes(srf_nogt(:,0))
nlon=dimsizes(srf_nogt(0,:))
print(nlon)
print(nlat)
printVarSummary(srf_nogt)

srf_rad:=srf_nogt/(Rnogt*Rnogt)

x_nogt=nlat
y_nogt=nlon
srf_rad!0="y_nogt"
srf_rad!1="x_nogt"

printVarSummary(srf_rad)

fo1->$"nogt.srf"$=srf_rad

;++++++++++++++++++++++++++++++++
Rnogt=6371229.
nlat=dimsizes(srf_torc(:,0))
nlon=dimsizes(srf_torc(0,:))
print(nlon)
print(nlat)
printVarSummary(srf_torc)

srf_rad:=srf_torc/(Rnogt*Rnogt)

x_torc=nlat
y_torc=nlon
srf_rad!0="y_torc"
srf_rad!1="x_torc"

printVarSummary(srf_rad)

fo1->$"torc.srf"$=srf_rad

end
