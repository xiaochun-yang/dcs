


class DcssHardwareProtocolHandler {
   inherit DCS::SocketProtocol
   private variable _serverName ""

   constructor {serverName sockHandle clientsAddress clientsPort args} {
      set _serverName $serverName
      set _socket $sockHandle
      set _otheraddr $clientsAddress
      set _otherPort $clientsPort
      
      fconfigure $_socket -translation binary -encoding binary -blocking 0
      fileevent $_socket readable "$this handleFirstReadableEvent"

      eval configure $args

      set _connectionGood 1
   }

   public method handleCompleteMessage { } {
      puts "HANDLE complete message $_textMessage"
      set _socketGood 1
      if { $callback != "" } {
         eval [concat $callback {$this $_textMessage $_binaryMessage }]
      }
   }

   public method handleNetworkError {message } {
      puts "$this network error: $message"
      if { [catch {close $_socket} result] } {
         puts "closed socket with result: $result"
      } else {
         $_serverName breakConnection $this
      }
      #deconstruct this object
      delete object $this
   }

   public method handleFirstReadableEvent {} {

      # make sure socket connection is still open
      if { [eof $_socket] } {
         handle_network_error "Connection closed to server."
         return
      }

      # read a message from the server
      if { [catch {set message [read $_socket 200]}] } {
         handle_network_error "Error reading from server."
         return
      }

      if { [lindex [split $message] 0] != "htos_client_type_is_hardware" } {
         handle_network_error "Error reading client type."
         return
      } 

      set lengthReceived [string length $message]
    
      #reprogram the event handler to be non-blocking
      fconfigure $_socket -translation binary -encoding binary -blocking 0 -buffering none
      fileevent $_socket readable "$this handleReadableEvent"
   }

}

class MockDcssHardwarePort {
   private variable _client ""
   private variable _socket
   private variable _port

   constructor {port_} {
      global lastMessageToDcss
      global messageChange
      qinit lastMessageToDcss
      set messageChange 0

      set _port $port_
      set _socket [socket -server [::itcl::code $this accept] $port_]
   }

   public method accept {sd_ address_ port_} {
      puts "MOCK DCSS HANDLE CONNECT $sd_ $address_ $port_"

      if { [info exists $_client] } {
         puts "client already connected"
         close $sd_
         return
      }
      set _client [DcssHardwareProtocolHandler #auto $this $sd_ $address_ $port_ -callback [::itcl::code $this handleClientInput]]
      $_client send_to_server "stoc_send_client_type"
   }

   public method handleClientInput { client_ message_ args} {
      #if {[catch {gets $client_ message_} rc]} {	
      #   puts $rc
      #   return	
      #}
      
      #if {$message_ == ""} return

      puts "DCSS<DHS: $message_"
      global lastMessageToDcss
      global messageChange
      qput lastMessageToDcss $message_
      set messageChange 0
   }

   public method breakConnection { client_ } {
      puts "disconnect from dcss"
      if {! [info exists $client_]} return

      delete object $client_
   }

   public method sendMessageToClient {message_} {
      $_client sendMessage $message_
   }

   public method waitForMessages { num } {
      global lastMessageToDcss
      global messageChange
      vwait messageChange

      set size [llength $lastMessageToDcss]
      if { $size == $num } {
         return
      } else {
         waitForMessages $num
      }
   }


}


class MockPilatusServer {
    private variable _socket 
    private variable _exptime ""

   constructor {port_} {
      if {[catch {	
         socket -server [::itcl::code $this accept] $port_	
      } _socket]} {	
         puts "ERROR Could not create mock server socket for Pilatus: $_socket"	
         return -code error	
	  }
   } 

   public method accept {sd_ address_ port_} {
      puts "MOCK PILATUS HANDLE CONNECT $sd_"
      fconfigure $sd_ -buffering line
      fileevent $sd_ readable [::itcl::code $this handleClientInput $sd_]
   }

    public method handleClientInput { sd_ } {
        if {[catch {gets $sd_ data} rc]} {	
            return	
        }
        puts "PILATUS<DHS: $data"
        set tokens [split $data]

        switch [lindex $tokens 0] {
            exttrigger {
                if {$_exptime==""} {
                    toDhs $sd_ "15 OK Starting externally triggered exposure(s): 2009/Jul/10 10:36:22.2837 ERR"
                    after [expr $_expTime * 1000] [::itcl::code $this sendExposeCompleteResponse $sd_ $_filename]
                    return
                }

                set filename [lindex $tokens 1]
                toDhs $sd_ "15 OK Exposure time set to: $_exptime sec.15 OK Starting externally triggered exposure(s): 2009/Jul/10 10:43:49.748"
            }
            exptime {
                set _exptime [lindex $tokens 1]
                toDhs $sd_ "15 OK Exposure time set to: $_exptime sec."
            }

        }

    }

    public method sendExposeCompleteResponse {sd_ filename_} {
        toDhs $sd_ "7 OK $filename_"
    }

    public method breakConnection {} {
        puts "disconnect from dcss"
    }
    
    private method toDhs { sd_ msg } {
        puts -nonewline $sd_ $msg
        endLine $sd_
    }

    private method endLine {sd_ } {
        puts -nonewline $sd_ [format %c "24"]
        flush $sd_
    }

}

proc testDetector {} {
    global env
    global lastMessageToDcss
    global messageChange

    puts "Start test"
    ::detector configure -testMode true 

    set user $env(USER)
    if {$user == "det"} {
        set user scottm
    }

    set sessionFile ~/.bluice/session
    if {! [file exists $sessionFile]} {
        puts "could not run test: file not found $sessionFile"
        return
    } 
    
    set sessionHandle [open $sessionFile]
    set session [gets $sessionHandle]
    close $sessionHandle

    #test a normal run with extra aborts at the end
    $::mockDcss sendMessageToClient "stoh_start_operation detector_collect_image 1.1  1 test10_11_42 /data/$user $user gonio_phi 1.0 0.0 1.0 300.0 12345.0 0.0 0.0 1 0 PRIVATE$session"
    $::mockDcss waitForMessages 1
    assertEquals "htos_operation_update detector_collect_image 1.1 start_oscillation shutter 1.0 test10_11_42" [qget lastMessageToDcss] 

    $::mockDcss sendMessageToClient "stoh_start_operation detector_transfer_image 1.2"
    $::mockDcss waitForMessages 1
    assertEquals "htos_operation_completed detector_transfer_image 1.2 normal" [qget lastMessageToDcss]
    $::mockDcss waitForMessages 1
    assertEquals "htos_operation_completed detector_collect_image 1.1 normal" [qget lastMessageToDcss]

    $::mockDcss waitForMessages 1
    assertEquals "htos_set_string_completed lastImageCollected normal /data/$user/test10_11_42.cbf" [qget lastMessageToDcss]

    $::mockDcss sendMessageToClient "stoh_start_operation detector_collect_image 1.3  1 test10_11_25 /data/$user $user gonio_phi 1.0 0.0 1.0 300.0 12345.0 0.0 0.0 1 0 PRIVATE$session"
    $::mockDcss waitForMessages 1
    assertEquals "htos_operation_update detector_collect_image 1.3 start_oscillation shutter 1.0 test10_11_25" [qget lastMessageToDcss]

    $::mockDcss sendMessageToClient "stoh_start_operation detector_transfer_image 1.4"

    $::mockDcss waitForMessages 1
    assertEquals "htos_operation_completed detector_transfer_image 1.4 normal" [qget lastMessageToDcss]


    $::mockDcss waitForMessages 1
    assertEquals "htos_operation_completed detector_collect_image 1.3 normal" [qget lastMessageToDcss]

    $::mockDcss waitForMessages 1
    assertEquals "htos_set_string_completed lastImageCollected normal /data/$user/test10_11_25.cbf" [qget lastMessageToDcss]

    $::mockDcss sendMessageToClient "stoh_start_operation detector_collect_image 1.5  1 test10_02_36 /data/$user $user gonio_phi 1.0 0.0 1.0 300.0 12345.0 0.0 0.0 1 0 PRIVATE$session"
    $::mockDcss waitForMessages 1
    assertEquals "htos_operation_update detector_collect_image 1.5 start_oscillation shutter 1.0 test10_02_36" [qget lastMessageToDcss]

    $::mockDcss sendMessageToClient "stoh_start_operation detector_transfer_image 1.6"

    $::mockDcss waitForMessages 1
    assertEquals "htos_operation_completed detector_transfer_image 1.6 normal" [qget lastMessageToDcss]

    $::mockDcss waitForMessages 1
    assertEquals "htos_operation_completed detector_collect_image 1.5 normal" [qget lastMessageToDcss]


    $::mockDcss waitForMessages 1
    assertEquals "htos_set_string_completed lastImageCollected normal /data/$user/test10_02_36.cbf" [qget lastMessageToDcss]


    $::mockDcss sendMessageToClient "stoh_start_operation detector_stop 1.7"
    $::mockDcss waitForMessages 1
    assertEquals "htos_operation_completed detector_stop 1.7 normal" [qget lastMessageToDcss]

    $::mockDcss sendMessageToClient "stoh_start_operation detector_stop 1.8"
    $::mockDcss waitForMessages 1
    assertEquals "htos_operation_completed detector_stop 1.8 normal" [qget lastMessageToDcss] 

    #test start and stop like a snapshot...
    $::mockDcss sendMessageToClient "stoh_start_operation detector_collect_image 1.9  1 test10_02_36 /data/$user $user gonio_phi 1.0 0.0 1.0 300.0 12345.0 0.0 0.0 1 0 PRIVATE$session"
    $::mockDcss sendMessageToClient "stoh_start_operation detector_stop 1.10"
    $::mockDcss waitForMessages 3
    assertEquals "htos_operation_update detector_collect_image 1.9 start_oscillation shutter 1.0 test10_02_36" [qget lastMessageToDcss]
    assertEquals "htos_operation_completed detector_collect_image 1.9 normal" [qget lastMessageToDcss]
    assertEquals "htos_operation_completed detector_stop 1.10 normal" [qget lastMessageToDcss]
    exit
}

proc assertEquals {str1 str2} {
   if {$str1 != $str2} {
      return -code error "expected '$str1' but got '$str2'"
   } 
}


set mockDcss [MockDcssHardwarePort #auto [config getDcssHardwarePort]]

#MockPilatusServer mockPilatusServer [::config getStr pilatus.port]