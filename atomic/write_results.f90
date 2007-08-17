!
! Copyright (C) 2004 PWSCF group
! This file is distributed under the terms of the
! GNU General Public License. See the file `License'
! in the root directory of the present distribution,
! or http://www.gnu.org/copyleft/gpl.txt .
!
!--------------------------------------------------------------
subroutine write_results 
  !--------------------------------------------------------------
  use radial_grids, only : ndmx
  use kinds,        only : dp
  use io_global, only : stdout, ionode_id, ionode
  use mp,        only : mp_bcast
  use constants, only : rytoev, eps6
  use ld1inc,    only : title, rel, zed, lsd, nspin, isic, latt, beta, tr2, &
                        grid, enzero, etot, ekin, encl, ehrt, evxt, ecxc, &
                        nwf, nn,ll,jj,el,isw,oc,enl, file_wavefunctions, &
                        dhrsic, dxcsic, eps0,iter, psi
  use funct, only :  get_iexch, get_dft_name
  implicit none

  integer :: is, i, j, n, m, im(40), l, ios
  real(DP):: work(ndmx), dum, int_0_inf_dr, ravg, r2avg, sij, ene, mm
  logical :: ok, oep
  character (len=20) :: dft_name
  !
  !
  dft_name = get_dft_name()
  write(stdout,'(5x,27(''-''),'' All-electron run '',28(''-''),/)')
  write(stdout,1150) title
  if(rel.eq.1) write(stdout,'(5x,''scalar relativistic calculation'')')
  if(rel.eq.2) write(stdout,'(5x,''dirac relativistic calculation'')')
1150 format(5x,a75)
  if (zed.ne.0.0) write(stdout,1250) zed
1250 format(/5x,'atomic number is',f6.2)
  write(stdout,2300) dft_name(1:len_trim(dft_name)),lsd,isic,latt,beta,tr2
2300 format(5x,'dft =',a,'   lsd =',i1,' sic =',i1,' latt =',i1, &
       '  beta=',f4.2,' tr2=',1pe7.1)
  write(stdout,1270) grid%mesh,grid%r(grid%mesh),grid%xmin,grid%dx
1270 format(5x,'mesh =',i4,' r(mesh) =',f10.5,' xmin =',f6.2,' dx =',f8.5)
  if (rel.lt.2) then
     write(stdout,1000)
1000 format(/5x, &
          'n l     nl                  e(Ry) ','         e(Ha)          e(eV)')

     oep = get_iexch() .eq. 4
     if (oep) enl(1:nwf) = enl(1:nwf) - enzero(isw(1:nwf))
     do n=1,nwf
        if (oc(n)>-eps6) write(stdout,1100) &
             nn(n),ll(n),el(n),isw(n),oc(n),enl(n),enl(n)*0.5_dp, &
             enl(n)*rytoev
     enddo
     if (oep) then
        enl(1:nwf) = enl(1:nwf) + enzero(isw(1:nwf))
        write(stdout,*) 
!!1100 format(4x,2i2,5x,a2,i2,'(',f5.2,')',f15.4,f15.4,f15.4)
        write(stdout,'(5x,a)') "OEP WARNING: printed eigenvalues were shifted by"
        if (nspin==1) write(stdout,'(17x,a,3f15.4)') ( "shift :", &
                            enzero(is), enzero(is)*0.5_dp, &
                            enzero(is)*rytoev, is=1,nspin)
        if (nspin==2) write(stdout,'(8x,a,i2,3x,a,3f15.4)') ( "spin",is,"shift :", &
                            enzero(is), enzero(is)*0.5_dp, &
                            enzero(is)*rytoev, is=1,nspin)
     end if
  else
     write(stdout,1001)
1001 format(/5x, &
          'n l j   nl                  e(Ry) ','         e(Ha)          e(eV)')
     write(stdout,'(5x,"Spin orbit split results")')
     do n=1,nwf
        if (oc(n)>-eps6) write(stdout,1120) &
            nn(n),ll(n),jj(n),el(n),isw(n),oc(n),enl(n),enl(n)*0.5_dp, &
            enl(n)*rytoev
     enddo
     write(stdout,'(5x,"Averaged results")')
     ok=.true.
     do n=1,nwf
        if (oc(n)+oc(n+1)>-eps6) then
           if (ll(n).gt.0.and.ok) then
              ene=(enl(n)*2.0_dp*ll(n) &
                   + enl(n+1)*(2.0_dp*ll(n)+2.0_dp))/(4.0_dp*ll(n)+2.0_dp)
              write(stdout,1100) nn(n),ll(n),el(n), isw(n),oc(n)+oc(n+1), &
                   ene,ene*0.5_dp, ene*rytoev
              ok=.false.
           else
              if (ll(n).eq.0) &
                   write(stdout,1100) nn(n),ll(n),el(n),isw(n),oc(n), &
                   enl(n),enl(n)*0.5_dp,enl(n)*rytoev
              ok=.true.
           endif
        endif
     enddo
  endif
1100 format(4x,2i2,5x,a2,i2,'(',f5.2,')',f15.4,f15.4,f15.4)
1120 format(4x,2i2,f4.1,1x,a2,i2,'(',f5.2,')',f15.4,f15.4,f15.4)
  write(stdout,1200) eps0,iter
1200 format(/5x,'eps =',1pe8.1,'  iter =',i3)
  write(stdout,*)
  write(stdout,'(5x,''Etot ='',f15.6,'' Ry,'',f15.6,'' Ha,'',f15.6,'' eV'')') &
       etot, etot*0.5_dp, etot*rytoev
  if (lsd.eq.1) then
     mm=0.d0
     do n=1,nwf
        if (oc(n).gt.0.0_dp) then
           if (isw(n).eq.1) mm=mm+oc(n)
           if (isw(n).eq.2) mm=mm-oc(n)
        endif
     enddo
     write(stdout,'(5x,''Total magnetization:'',f8.2,'' Bohr mag. '')') mm
  endif
  write(stdout,'(/,5x,''Ekin ='',f15.6,'' Ry,'',f15.6,'' Ha,'',f15.6,'' eV'')')&
       ekin, ekin*0.5_dp,  ekin*rytoev
  write(stdout,'(5x,''Encl ='',f15.6,'' Ry,'',f15.6,'' Ha,'',f15.6,'' eV'')')&
       encl, encl*0.5_dp, encl*rytoev
  write(stdout,'(5x,''Eh   ='',f15.6,'' Ry,'',f15.6, '' Ha,'',f15.6,'' eV'')') &
       ehrt, ehrt*0.5_dp, ehrt*rytoev
  write(stdout,&
       '(5x,''Exc  ='',f15.6,'' Ry,'',f15.6,'' Ha,'',f15.6,'' eV'')') &
       ecxc, ecxc*0.5_dp, ecxc*rytoev
  write(stdout,&
       '(5x,''Evxt ='',f15.6,'' Ry,'',f15.6,'' Ha,'',f15.6,'' eV'')') &
       evxt, evxt*0.5_dp, evxt*rytoev
  if (isic.ne.0) then
     write(stdout,*)
     write(stdout,'(5x,"SIC information:")') 
     write(stdout,1300) dhrsic, dhrsic*0.5_dp, dhrsic*rytoev 
     write(stdout,2310) dxcsic, dxcsic*0.5_dp, dxcsic*rytoev
     write(stdout,2320) dxcsic+dhrsic,(dxcsic+dhrsic)*0.5_dp, &
                       (dxcsic+dhrsic)*rytoev  
     write(stdout,*)
     write(stdout,2311) ecxc-dxcsic-dhrsic, &
          &  (ecxc-dxcsic-dhrsic)*0.5_dp, (ecxc-dxcsic-dhrsic)*rytoev 
     write(stdout,2312) ecxc-dhrsic, &
          &               (ecxc-dhrsic)*0.5_dp, (ecxc-dhrsic)*rytoev 
     write(stdout,2313) ehrt+dhrsic, &
          &              (ehrt+dhrsic)*0.5_dp, (ehrt+dhrsic)*rytoev 
1300 format(5x,'Esich=',f15.6,' Ry,',f15.6,' Ha,',f15.6,' eV') 
2310 format(5x,'Esicxc=',f14.6,' Ry,',f15.6,' Ha,',f15.6,' eV') 
2311 format(5x,'tot-Exc=',f13.6,' Ry,',f15.6,' Ha,',f15.6,' eV') 
2312 format(5x,'int-Exc=',f13.6,' Ry,',f15.6,' Ha,',f15.6,' eV') 
2313 format(5x,'int-Eh=',f14.6,' Ry,',f15.6,' Ha,',f15.6,' eV') 
2320 format(5x,'Esictot=',f13.6,' Ry,',f15.6,' Ha,',f15.6,' eV') 
  endif
  write(stdout,1310)
1310 format(//5x,'normalization and overlap integrals'/)

  do i=1,nwf
     dum=0.0_dp
     do m=1,grid%mesh
        dum=max(dum,abs(psi(m,1,i)))
        if(dum.eq.abs(psi(m,1,i)))im(i)=m
     enddo
  enddo

  do i=1,nwf
     do j=i,nwf
        if (ll(i)==ll(j).and.jj(i)==jj(j).and.isw(i).eq.isw(j).and. &
            oc(i).ge.-1.d-12.and.oc(j).ge.-1.d-12) then
           if (rel<2) then
              do m=1,grid%mesh
                 work(m)=psi(m,1,i)*psi(m,1,j)
              enddo
           else
              do m=1,grid%mesh
                 work(m)=psi(m,1,i)*psi(m,1,j)+psi(m,2,i)*psi(m,2,j)
              enddo
           endif
           sij = int_0_inf_dr(work,grid,grid%mesh,2*ll(i)+2)
           if (i.eq.j) then
              do m=1,grid%mesh
                 work(m)=work(m)*grid%r(m)
              enddo
              ravg = int_0_inf_dr(work,grid,grid%mesh,2*ll(i)+3)
              do m=1,grid%mesh
                 work(m)=work(m)*grid%r(m)
              enddo
              r2avg = int_0_inf_dr(work,grid,grid%mesh,2*ll(i)+4)
              write(stdout,1400) el(i),el(j),sij, ravg, r2avg, grid%r(im(i))
           else
              write(stdout,1401) el(i),el(j),sij
           endif
        endif
     enddo
  enddo
1400 format(5x,'s(',a2,'/',a2,') =',f10.6,2x, &
       '<r> =',f9.4,2x,'<r2> =',f10.4,2x,'r(max) =',f9.4)
1401 format(5x,'s(',a2,'/',a2,') =',f10.6)

  if (file_wavefunctions.ne.' ') then
     if (ionode) &
        open(unit=15,file=file_wavefunctions,status='unknown',  &
          err=1110, iostat=ios,form='formatted')
1110 call mp_bcast(ios,ionode_id)
     call errore('write_result','opening file_wavefunctions',abs(ios))
     if (ionode) then
        write(15,'("#     r",7(8x,a2))') (el(i),i=nwf,max(1,nwf-6),-1)
        do n=1,grid%mesh 
           write(15,'(8f10.6)') grid%r(n),(psi(n,1,i),i=nwf,max(1,nwf-6),-1)
        enddo
        close(15)
     endif
  endif
  write(stdout,'(/,5x,24(''-''), '' End of All-electron run '',24(''-''),/)')

  return
end subroutine write_results
