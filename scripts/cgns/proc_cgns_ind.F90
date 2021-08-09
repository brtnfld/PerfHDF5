PROGRAM main

  IMPLICIT NONE

  INTEGER :: i,j
  INTEGER :: nf, nfiles, nlines, ntimes, numtests
  CHARACTER(LEN=180), DIMENSION(:), ALLOCATABLE :: files
  CHARACTER(180):: filename,filename2,filename3
  CHARACTER(180) :: cmd, cmd_in
  CHARACTER(4000) :: input
  REAL, DIMENSION(1:20,1:4) :: values
  INTEGER err
  INTEGER indx, indx2, num
  CHARACTER(LEN=10) :: vers
  CHARACTER(LEN=80), ALLOCATABLE, DIMENSION(:) :: chr
  REAL, DIMENSION(:,:), ALLOCATABLE :: time
  REAL rtime

  CALL EXECUTE_COMMAND_LINE("\ls IND_TIME.* | wc -l > src_files")
  CALL EXECUTE_COMMAND_LINE("\ls IND_TIME.* >> src_files")
  OPEN(10,file="src_files", status="old")
  READ(10,*) nfiles
  ALLOCATE(files(1:nfiles))
  DO i = 1, nfiles
     READ(10,*) files(i)
  ENDDO
  CLOSE(10, status='delete')
  
  CALL EXECUTE_COMMAND_LINE("rm -fr cgns_indtime.dat")

  DO nf = 1, nfiles

     cmd_in = "wc -l "//TRIM(files(nf))//" > src"
     CALL EXECUTE_COMMAND_LINE(TRIM(cmd_in))

     OPEN(12,FILE="src")
     READ(12,*) nlines
     CLOSE(12, status='delete')
     nlines = nlines - 1

     OPEN(12,FILE=files(nf))

     READ(12,*) vers, ntimes

     DO i = 1, LEN(TRIM(vers))
        IF(vers(i:i).EQ."_")THEN
           vers(i:i)="."
        ENDIF
     ENDDO

     IF(MOD(nlines,ntimes).NE.0)THEN
        PRINT*,"ERROR: Number of output lines not equal for each run"
        STOP
     ENDIF

     numtests = nlines/ntimes

     IF(.NOT.ALLOCATED(time))THEN
        ALLOCATE(time(1:numtests,1:3))
        ALLOCATE(chr(1:numtests))
     ENDIF

     time(:,1) = 0.
     time(:,2) = HUGE(1.)
     time(:,3) = 0.
     DO i = 1, ntimes
        DO j = 1, numtests
           READ(12,*) chr(j), rtime
           time(j,1) = time(j,1) + rtime
           time(j,2) = MIN(time(j,2), rtime)
           time(j,3) = MAX(time(j,3), rtime)
        ENDDO
     ENDDO

     time(:,1) = time(:,1)/ntimes

     CLOSE(12)

     OPEN(16,file="cgns_indtime.dat", position="append")
     IF(nf.EQ.1)THEN
        WRITE(16,'(A,X)', advance="no") "version"
        DO i = 1, numtests
           WRITE(16,'(A,X)', advance="no") TRIM(chr(i))
        ENDDO
        WRITE(16,'()')
     ENDIF
     WRITE(16,*) TRIM(vers), time(:,1)
     
     CLOSE(16)
  ENDDO

  cmd_in = "sed -i 's/_/\\\\\\\_/g'"//" cgns_indtime.dat"
  CALL EXECUTE_COMMAND_LINE(TRIM(cmd_in))

END PROGRAM main

           
           
        
        

        

        

     
