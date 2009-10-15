#!/usr/bin/perl

#############################################################
## Ver0.1: Hongquan Zuo , modified, 07/07/07
##          zuohongquan@163.com
#############################################################

#   Version 0.1        --07/07/07
#   1.Split code into some sub fuctions.
#   2.Format printing.
#   3.Deal with same name input.
############################################################# 
check_argv();
file_list();
real_name();
mapfile();
inner_port();
same_name_input();

####################        file.list       #######################
$show_infor = 0;
$sel_format = 32;
sub check_argv{
    foreach (@ARGV){
        $show_infor = ($_ eq "-debug") ? 1 : 0;
    }
}


####################        file.list       #######################
sub file_list{
    if (open(FILEI, "file.list")) {
        print "Open file file.list to read! \n"
    }
    else {
        die ("Cannot open the file file.list! \n");
    }
    
    @array_file = <FILEI>;
    $i=0;#inport index
    $j=0;#outport index
    foreach $line (@array_file) {
        $line =~ s/[\015\012]//;#change ^M to enter
        $line =~ s/\t//g;#delete Tab
        $line =~ s/ +//g;#delete the spaces 
        $firstbit_line = substr($line, 0,1);#get first char
        #if(($firstbit_map_line ne "#") && ($firstbit_map_line ne "\n")){
        if($line !~ /^#|^\n/){
            ($hirachy,$module_name,$instance_number,$file_path,$instance_name)= split(/:/, $line); 
    
            $instance_number_temp = $instance_number;
            
            while ($instance_number >= 1){  
                $instance_real_number = $instance_number_temp - $instance_number;     
                if($instance_number_temp == 1){
                    $instance_name = $instance_name ? $instance_name : "u_$module_name";
                }
                else{
                    $instance_name = "u$instance_real_number\_$module_name";
                }
                
                if ($hirachy eq "top") {
                    $top = $module_name;
                }
                elsif ($hirachy eq "sub") {
                    chomp($file_path);#delete "\n" and $file_path is full path
                    if (open(SUBFILE, "$file_path")) {
                        print "Open file $file_path to read! \n"
                    }
                    else {
                        die ("Cannot open the file $file_path! \n");
                    }
    #                push @submodule_name, $module_name;
                    push @subinstance_name,$instance_name;
                    $instance_list{$instance_name} = $module_name;
                    #$instance_times{$instance_name} = $instance_number_temp;
    
                    $comment_turnon = 0;#commnet flag
                    @array_port = <SUBFILE>;
                    SUBMOD:foreach $sub_line (@array_port) {
                        #$sub_line =~ s/[\015\012]//;#delete ^M
                        #$sub_line =~ s/\t//g;#delete Tab
                        ##jason
                        #$sub_line =~ s/^ +//g;#delete the spaces at beginning
                        #if($sub_line =~ /^parameter/){
                        #    push @para_arry,$sub_line;
                        #}
                        $sub_line =~ s/\t/ /g;#delete all Tab
                        $sub_line =~ s/ wire //g;
                        $sub_line =~ s/ wire\[/\[/g;
                        $sub_line =~ s/ +//g;#delete all spaces 
                        #print ("$sub_line");
                        #only need input/output information,if meet "wire",the input/out declaration is finished
                        #if($sub_line =~ /^wire/){
                        #    last SUBMOD;
                        #}
                        if($sub_line =~ /^\/\*/){
                            $comment_turnon = 1;
                            print("comment turn on\n ");
                        }
                        #comment_turnon, deal with 
                        #/*
                        #input
                        #*/
                        if($comment_turnon==1){}
                        elsif($sub_line =~ /^input/){
                            $port_dir = $&;
                            $' =~ /;/;
                            $sub_line = $`;
                            #handle "input wire [x:x] aaa;"
                            $sub_line =~ s/^ +//;
                            #$sub_line =~ s/^wire +//;
                            if($sub_line =~ /\[.*\]/){
                                $bit_num = $&;
                                $sub_line = $';
                                $bit_num =~ s/ +//g;
                            }
                            else {
                                $bit_num = "";
                            }
                            #don't deal with "input a;input b;" 
                            #can deal with "input a,b;"
                            @port_line = split(/,/, $sub_line);
                            foreach $iport (@port_line) {#now $inport is port name,#port_line is input a,b,c,...
                                $iport_fullname_temp = join("_",($instance_name,$iport));
                                chomp($iport);
                                push @iport_array,$iport;
                                push @iport_instance,$instance_name;
                                push @iport_bits,$bit_num;
                                push @iport_useinfo,$port_dir;
                                push @iport_fullname,$iport_fullname_temp;
                                push @iport_realname,$iport;
                                push @$instance_name, $iport;#array of the in port name for each instance
                                $iport_index{$iport_fullname_temp} = $i; 
                                $i++;
                            }
                        }
                        elsif($sub_line =~ /^output/){
                            $port_dir = $&;
                            $' =~ /;/;
                            $sub_line = $`;
                            #handle "output wire [x:x] aaa;"
                            $sub_line =~ s/^ +//;
                            if($sub_line =~ /\[.*\]/){
                                $bit_num = $&;
                                $sub_line = $';
                                $bit_num =~ s/ +//g;
                            } 
                            else {
                                $bit_num = "";
                            }
                            #don't deal with "input a;input b;" 
                            #can deal with "input a,b;"
                            @port_line = split(/,/, $sub_line);
                            foreach $oport (@port_line) {#now $onport is port name,#port_line is output a,b,c,...
                                $oport_fullname_temp = join("_",($instance_name,$oport));

                                chomp($oport);
                                push @oport_array,$oport;
                                push @oport_instance,$instance_name;
                                push @oport_bits,$bit_num;
                                push @oport_useinfo,"output";
                                push @oport_fullname,$oport_fullname_temp;
                                push @oport_realname,$oport;
                                push @$instance_name, $oport;#array of the in port name for each instance 
                                $oport_index{$oport_fullname_temp} = $j;
                                $j++;
                            }
                        }
                        if($sub_line =~ /\*\//){
                            $comment_turnon = 0;
                            print("comment turn off\n");
                        }
                    }
                }
                $instance_number--;
    #            print("\$instance_name is $instance_name -------\$instance_number is $instance_number\n");
            }
        }
    }
}


################# push realname##################
#compare oport with all oport,if the ports' names are same and they are not from same instance, 
#the port's real name is instancename_portname, otherwise is portname; 
#this is same to iport. 
sub real_name{
    for($i=0;$i < @iport_array;$i++){
        for($j=($i+1);$j < @iport_array;$j++){
            if(($iport_array[$i] eq $iport_array[$j]) && ($iport_instance[$i] ne $iport_instance[$j])){
                $iport_realname[$i] = $iport_fullname[$i];
                $iport_realname[$j] = $iport_fullname[$j];
            }
        }  
    
    }
    for($i=0;$i < @oport_array;$i++){
        for($j=($i+1);$j < @oport_array;$j++){
            if(($oport_array[$i] eq $oport_array[$j]) && ($oport_instance[$i] ne $oport_instance[$j])){
                $oport_realname[$i] = $oport_fullname[$i];
                $oport_realname[$j] = $oport_fullname[$j];
            }
        }  
    }
}


#while(($key,$value) = each(%iport_index)){
#    print("\$iport key = $key ,value = $value \n");
#}
#while(($key,$value) = each(%oport_index)){
#    print("\$oport key = $key ,value = $value \n");
#}

##############          mapfile         ############
sub mapfile{
    if (open(MAPFILE, "mapfile")) {
        print ("Open file mapfile to read! \n");
    }
    else {
        print ("Cannot open the file mapfile! \n");
    }
    
    @map_array = <MAPFILE>;
    $i=0;
    $j=0;
    foreach $map_line (@map_array) {
        $map_line_temp = $map_line;
        $map_line =~ s/\t//g;#delete Tab
        $map_line =~ s/ +//g;#delete the all spaces
        ($map_line_firstword,$others) = split(/\!/,$map_line_temp);
        $map_line_firstword =~ s/ +//g;
        #$others =~ s/^ +//;
        chomp($others);
        if($map_line =~ /^\*/){
            if($map_line_firstword eq "\*write_include"){
                push @write_include,$others;
            }
            elsif($map_line_firstword eq "\*write_port"){
                push @write_port,$others;
            }
            elsif($map_line_firstword eq "\*write_para"){
                push @write_para,$others;
            }
            elsif($map_line_firstword eq "\*write_wire"){
                push @write_wire,$others;
            }
            elsif($map_line_firstword eq "\*write_assign"){
                push @write_assign,$others;
            }
            elsif($map_line_firstword eq "\*add_para"){
                #write parameter for sub instance
                $others =~ s/ +//;
                $others =~ /:/;
                $sub_para{$`} = $';
                #print "^^^$`^^^$'^^^$sub_para{$`}\n";
            }
            #user mask the input/output assertion
            elsif($map_line_firstword eq "\*add_mask"){
                $others =~ s/\./_/;
                $map_rport_fullname_temp = $others;
                #print("****$others***\n");
                if(exists $oport_index{$map_rport_fullname_temp}){
                    $rstate = "out";
                    $map_oport_index_intable_temp = $oport_index{$map_rport_fullname_temp};
                    $oport_useinfo[$map_oport_index_intable_temp] = "mask";
                }
                elsif(exists $iport_index{$map_rport_fullname_temp}){
                    $rstate = "in";
                    $map_iport_index_intable_temp = $iport_index{$map_rport_fullname_temp};
                    $iport_useinfo[$map_iport_index_intable_temp] = "mask";
                }
            }
            elsif($map_line =~ /\*sel_format=/) {$sel_format=$';}
            else{
                print("do nothing!\n");
            }
        }
        elsif($map_line !~ /^#|^\n/){
            #separate the mapfile information
    
            ($map_lname,$map_rname) = split(/\!/,$map_line); 
            chomp($map_rname);
            
            ($map_lport_instance_temp,$map_lport_namebits_temp)= split(/\./,$map_lname); 
            ($map_lport_name_temp,$map_lport_bitrange_temp) = split(/\[/,$map_lport_namebits_temp);
            
            if($map_lport_bitrange_temp){
                $map_lport_bitrange_temp = "\[$map_lport_bitrange_temp";
            }
          
            ($map_rport_instance_temp,$map_rport_namebits_temp)= split(/\./,$map_rname);
            ($map_rport_name_temp,$map_rport_bitrange_temp) = split(/\[/,$map_rport_namebits_temp);
            if($map_rport_bitrange_temp){
                $map_rport_bitrange_temp = "\[$map_rport_bitrange_temp";
            }
            
            $map_lport_fullname_temp = join("_",($map_lport_instance_temp,$map_lport_name_temp));
            $map_rport_fullname_temp = join("_",($map_rport_instance_temp,$map_rport_name_temp));
            
            #check left port state
            if(exists $oport_index{$map_lport_fullname_temp}){
                $lstate = "out";
                $map_oport_index_intable_temp = $oport_index{$map_lport_fullname_temp};
                $oport_useinfo[$map_oport_index_intable_temp] = "mapped";
            }
            elsif(exists $iport_index{$map_lport_fullname_temp}){
                $lstate = "in";
                $map_iport_index_intable_temp = $iport_index{$map_lport_fullname_temp};
                $iport_useinfo[$map_iport_index_intable_temp] = "mapped";
            }
            elsif($map_lport_instance_temp eq $top){
                $lstate = "top";
            }
            elsif($map_lport_instance_temp eq "set"){
                $lstate = "set";
            }
            else{
                $lstate = "reserve";
            }
            
            #check right port state
            if(exists $oport_index{$map_rport_fullname_temp}){
                $rstate = "out";
                $map_oport_index_intable_temp = $oport_index{$map_rport_fullname_temp};
                $oport_useinfo[$map_oport_index_intable_temp] = "mapped";
            }
            elsif(exists $iport_index{$map_rport_fullname_temp}){
                $rstate = "in";
                $map_iport_index_intable_temp = $iport_index{$map_rport_fullname_temp};
                $iport_useinfo[$map_iport_index_intable_temp] = "mapped";
            }
            elsif($map_rport_instance_temp eq $top){
                $rstate = "top";
            }
            elsif($map_rport_instance_temp eq "set"){
                $rstate = "set";
            }
            else{
                $rstate = "reserve";
            }
            
            if((($lstate eq "out") && ($rstate eq "in")) 
            || (($lstate eq "out") && ($rstate eq "top")) 
            || (($lstate eq "top") && ($rstate eq "in"))){
                $map_oport_name_temp     = $map_lport_name_temp;    
                $map_oport_namebits_temp = $map_lport_namebits_temp;
                $map_oport_instance_temp = $map_lport_instance_temp;
                $map_oport_bitrange_temp = $map_lport_bitrange_temp;
                $map_oport_fullname_temp = $map_lport_fullname_temp;
                
                $map_iport_name_temp     = $map_rport_name_temp;    
                $map_iport_namebits_temp = $map_rport_namebits_temp;
                $map_iport_instance_temp = $map_rport_instance_temp;
                $map_iport_bitrange_temp = $map_rport_bitrange_temp;
                $map_iport_fullname_temp = $map_rport_fullname_temp; 
            }
            elsif((($rstate eq "out") && ($lstate eq "in")) 
            || (($rstate eq "out") && ($lstate eq "top")) 
            || (($rstate eq "top") && ($lstate eq "in"))){
                $map_oport_name_temp     = $map_rport_name_temp    ;    
                $map_oport_namebits_temp = $map_rport_namebits_temp;
                $map_oport_instance_temp = $map_rport_instance_temp;
                $map_oport_bitrange_temp = $map_rport_bitrange_temp;
                $map_oport_fullname_temp = $map_rport_fullname_temp;
                
                $map_iport_name_temp     = $map_lport_name_temp    ;    
                $map_iport_namebits_temp = $map_lport_namebits_temp;
                $map_iport_instance_temp = $map_lport_instance_temp;
                $map_iport_bitrange_temp = $map_lport_bitrange_temp;
                $map_iport_fullname_temp = $map_lport_fullname_temp; 
            }
            
                   
    #        print(" $map_oport_index_intable_temp ====$map_oport_fullname_temp  map out port\n");
    #        print(" $map_iport_index_intable_temp ====$map_iport_fullname_temp  map in port\n");
    #        print("\n");
    
    ####push map information     
    
            if((($lstate eq "out") && ($rstate eq "in")) 
            || (($lstate eq "in") && ($rstate eq "out"))){        
                push @map_oport_name    ,$map_oport_name_temp;
                push @map_oport_namebits,$map_oport_namebits_temp;
                push @map_oport_instance,$map_oport_instance_temp;
                push @map_oport_fullname,$map_oport_fullname_temp;
        #       push @map_oport_index_intable,$map_oport_index_intable_temp;
                push @map_oport_bitrange,$map_oport_bitrange_temp;
                push @map_oport_realname,$oport_realname[$map_oport_index_intable_temp];
        
        #        $aaa = @map_oport_bitrange;
        #        print("-------$aaa @map_oport_bitrange ))))) \n");
            
                $map_oport_index{$map_oport_fullname_temp} = $j;
                $j++;
            
                push @map_iport_name    ,$map_iport_name_temp;
                push @map_iport_namebits,$map_iport_namebits_temp;
                push @map_iport_instance,$map_iport_instance_temp;
                push @map_iport_fullname,$map_iport_fullname_temp;
                push @map_iport_bitrange,$map_iport_bitrange_temp;
                push @map_iport_realname,$iport_realname[$map_iport_index_intable_temp];
            
                $map_iport_index{$map_iport_fullname_temp} = $i;
                $i++;
                
                push @map_bits,$oport_bits[$map_oport_index_intable_temp];
            }
            elsif((($lstate eq "out") && ($rstate eq "top")) 
            || (($lstate eq "top") && ($rstate eq "out"))){   
                push @map_output_name    ,$map_oport_name_temp;
                push @map_output_namebits,$map_oport_namebits_temp;
                push @map_output_instance,$map_oport_instance_temp; 
                push @map_output_fullname,$map_oport_fullname_temp;
                push @map_output_bitrange,$map_oport_bitrange_temp;
                push @map_output_realname,$oport_realname[$map_oport_index_intable_temp];
                
                push @map_output_outname,$map_iport_name_temp;#output port namme on top module 
                
                if($map_oport_bitrange_temp){
                    $map_oport_bitrange_temp =~ s/[\[\]]//g;#delete "[" and "]";
                    ($map_oport_bitleft,$map_oport_bitright) = split(/\:/,$map_oport_bitrange_temp);
                    $map_oport_bitleft = $map_oport_bitleft - $map_oport_bitright;
                    $map_oport_bitright = 0;
                    $map_oport_bitrange_temp = "[$map_oport_bitleft:$map_oport_bitright]";
                }
                else{
                    $map_oport_bitrange_temp = $oport_bits[$map_oport_index_intable_temp];
                }
                push @map_output_bits,$map_oport_bitrange_temp;
                push @map_output_wirebits,$oport_bits[$map_oport_index_intable_temp];          
        #        push @map_output_index_intable,$map_oport_index_intable_temp
            }
            elsif((($lstate eq "in") && ($rstate eq "top")) 
            || (($lstate eq "top") && ($rstate eq "in"))){ 
                
                if($map_iport_bitrange_temp){
                    $map_iport_bitrange_temp =~ s/[\[\]]//g;#delete "[" and "]";
                    ($map_iport_bitleft,$map_iport_bitright) = split(/\:/,$map_iport_bitrange_temp);
                    $map_iport_bitleft = $map_iport_bitleft - $map_iport_bitright;
                    $map_iport_bitright = 0;
                    $map_iport_bitrange_temp = "[$map_iport_bitleft:$map_iport_bitright]";
                }
                else{
                    $map_iport_bitrange_temp = $iport_bits[$map_iport_index_intable_temp];
                }
                
                push @map_input_inname,$map_oport_name_temp;#input port namme on top module 
                push @map_input_name,$map_iport_name_temp;
                push @map_input_namebits,$map_iport_namebits_temp;
                push @map_input_instance,$map_iport_instance_temp; 
                push @map_input_fullname,$map_iport_fullname_temp;
                push @map_input_bitrange,$map_iport_bitrange_temp;
                push @map_input_realname,$iport_realname[$map_iport_index_intable_temp];
                push @map_input_state,"map_input";
               
                
                
                #$map_input_inname{$map_oport_name_temp} = $map_iport_fullname_temp;
                #$map_input_bits{$map_oport_name_temp} = $map_iport_bitrange_temp;
                
                $map_input_namebits_sub{$map_iport_fullname_temp} = $map_oport_namebits_temp;
                
            }
            elsif((($lstate eq "out") || ($lstate eq "in")) 
            && ($rstate eq "set")){
                $map_set_name{$map_lport_fullname_temp} = $map_rport_namebits_temp;    
            }
            elsif(($lstate eq "set") 
            && (($rstate eq "out") || ($rstate eq "in"))){
                $map_set_name{$map_rport_fullname_temp} = $map_lport_namebits_temp;    
            }
            else{
                print("There is error. left is $lstate : $map_lport_fullname_temp, right is $rstate : $map_rport_fullname_temp\n");
            }
        }
    
    }
}

########pick out inner port
sub inner_port{
    for($i=0;$i < @iport_array;$i++){
        for($j=0;$j < @oport_array;$j++){
            if(($iport_array[$i] eq $oport_array[$j]) && (($iport_useinfo[$i] ne "mapped")&&($oport_useinfo[$j] ne "mapped"))){
                $inner_wirebits{$oport_realname[$j]} = $oport_bits[$j];
                
    #            push @inner_realname,$oport_realname[$j];
    #            push @inner_bits,$oport_bits[$j]; 
                $iport_useinfo[$i] = "inner";
                $oport_useinfo[$j] = "inner";
                $iport_realname[$i] = $iport_array[$i];
    #            print("inner $iport_array[$i]\n");  
            }
        }    
    }
}
sub same_name_input{
    #pick out same name input in iport_array
    for($i=0;$i < @iport_array;$i++){
        for($j=0;$j < @iport_array;$j++){
            if(($iport_array[$i] eq $iport_array[$j]) && ($iport_instance[$i] ne $iport_instance[$j]) && ($iport_useinfo[$i] eq "input")){
                $iport_useinfo[$i] = "same_name_input";
                $samename_input{$iport_array[$i]}  = $iport_bits[$i]; 
                $iport_realname[$i] = $iport_array[$i];
            }
        }
    }
    #pick out same name input in map_input_inname
    for($i=0;$i < @map_input_name;$i++){
        for($j=0;$j < @map_input_name;$j++){
            if(($map_input_name[$i] eq $map_input_name[$j]) && ($map_input_instance[$i] ne $map_input_instance[$j]) && (($map_input_state[$j] eq "map_input") || ($map_input_state[$j] eq "map_input" ))){
                $map_input_state[$i] = "same_name_input";
                $map_input_state[$j] = "same_name_input";
                $samename_input{$map_input_name[$i]}  = $map_input_bitrange[$i]; 
                $iport_realname[$i] = $map_input_name[$i];
            }
        }
    }
    #pick out same name input in iport_array and map_input_inname
    for($i=0;$i < @iport_array;$i++){
        for($j=0;$j < @map_input_name;$j++){
            if(($iport_array[$i] eq $map_input_inname[$j]) && ($iport_instance[$i] ne $map_input_instance[$j]) && (($iport_useinfo[$i] eq "input") || ($map_input_state[$j] eq "map_input" ))){
                $iport_useinfo[$i] = "same_name_input";
                $map_input_state[$j] = "same_name_input";
                $samename_input{$iport_array[$i]}  = $iport_bits[$i]; 
                $iport_realname[$i] = $iport_array[$i];
            }
        }
    }
    while(($samename,$bits) = each(%samename_input)){
        push @samename_input_name,$samename;
        push @samename_input_bits,$bits;
    }
}




####################        $top.v.tmp      ##################
if (open(OUTFILE, ">$top.v.tmp")) {
    print "Open file $top.v.tmp to write! \n"
}
else {
    die ("Cannot open the file $top.v.tmp! \n");
}

#print OUTFILE ("\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\n");
#print OUTFILE ("\/\/ Automatic generated top file by top_hookup.pl!\n");
#print OUTFILE ("\/\/ Please use syntax check to make sure all the connections are right!\n");
#print OUTFILE ("\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\n\n");

if($show_infor) { $infor = "//-------------- direct write include begin ---------------\n"; }
else            { $infor = "";}
print OUTFILE ("$infor");
for($i=0;$i<@write_include;$i++){
        if($show_infor) { $infor = "//write include"; }
        else            { $infor = "";}
        print OUTFILE ("$write_include[$i] $infor\n");
}
if($show_infor) { $infor = "//-------------- direct write include end ---------------\n"; }
else            { $infor = "";}
print OUTFILE ("$infor");

print OUTFILE ("`delete comma\n");
print OUTFILE ("module $top \(\n");

format OUTFILE=
@<<<<<< @<<@* 
$space,$bits,$name
.

format F1=
@<<<<<< @<<<<<<<@* 
$space,$bits,$name
.
format F2=
@<<<<<< @<<<<<<<<<<<<<<<<@* 
$space,$bits,$name
.
format F3=
@<<<<<< @<<<<<<<<<<<<<<<<<<<<<<<<@* 
$space,$bits,$name
.
format F4=
@<<<<<< @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<@* 
$space,$bits,$name
.

sub write_file {
    select(\*OUTFILE);
    if($sel_format == 8) {$~ = "F1";}
    elsif($sel_format == 16){$~ = "F2";}
    elsif($sel_format == 24){$~ = "F3";}
    elsif($sel_format == 32){$~ = "F4";}
    write;
}

for($i=0;$i<@iport_array;$i++){
    if($iport_useinfo[$i] eq "input"){
        $space = "";
        $bits = "";
#        $name = "$iport_array[$i],\n";
        $name = ",$iport_realname[$i]\n";
        write OUTFILE;
    }
}
for($i=0;$i<@map_input_name;$i++){
    if($map_input_state[$i] eq "map_input"){
        $space = "";
        $bits = "";
        if($show_infor) { $infor = "//map_input port"; }
        else            { $infor = "";}
        $name = ",$map_input_inname[$i]    $infor\n";
        write OUTFILE;
    }
}
for($i=0;$i<@samename_input_name;$i++){
        $space = "";
        $bits = "";
        if($show_infor) { $infor = "//same name input port"; }
        else            { $infor = "";}
        $name = ",$samename_input_name[$i]    $infor\n";
        write OUTFILE;
}

for($i=0;$i<@oport_array;$i++){
    if($oport_useinfo[$i] eq "output"){
        $space = "";
        $bits = "";
        $name = ",$oport_realname[$i]\n";
        write OUTFILE;
    }
}

for($i=0;$i<@map_output_name;$i++){
        $space = "";
        $bits = "";
        if($show_infor) { $infor = "//map_output port"; }
        else            { $infor = "";}
        $name = ",$map_output_outname[$i]    $infor\n";
        write OUTFILE;
}
if($show_infor) { $infor = "//-------------- direct write port begin ---------------\n"; }
else            { $infor = "";}
print OUTFILE ("$infor");
for($i=0;$i<@write_port;$i++){
        $space = "";
        $bits = "";
        if($show_infor) { $infor = "//write port"; }
        else            { $infor = "";}
        $name = ",$write_port[$i]    $infor\n";
        write OUTFILE;
}
if($show_infor) { $infor = "//-------------- direct write port end ---------------\n"; }
else            { $infor = "";}
print OUTFILE ("$infor");
print OUTFILE ("\);\n\n");

if($show_infor) { $infor = "//-------------- direct write parameter begin ---------------\n"; }
else            { $infor = "";}
print OUTFILE ("$infor");
for($i=0;$i<@write_para;$i++){
        if($show_infor) { $infor = "//write para"; }
        else            { $infor = "";}
        print OUTFILE ("$write_para[$i] $infor\n");
}
if($show_infor) { $infor = "//-------------- direct write parameter end ---------------\n"; }
else            { $infor = "";}
print OUTFILE ("$infor");

#print OUTFILE ("////////////////        parameter    ////////////////\n");
#for($i=0;$i<@para_arry;$i++){
#    print OUTFILE ("$para_arry[$i]");
#}


print OUTFILE ("//------------------ input ----------------------\n");
for($i=0;$i<@iport_array;$i++){
    if($iport_useinfo[$i] eq "input") {
        $space = "input";
        $bits = $iport_bits[$i];
        $name = "$iport_array[$i];\n";
        write_file();
    }
}
for($i=0;$i<@samename_input_name;$i++){
        $space = "input";
        $bits = $samename_input_bits[$i];
        if($show_infor) { $infor = "//same name input"; }
        else            { $infor = "";}
        $name = "$samename_input_name[$i];    $infor\n";
        write_file();
}
for($i=0;$i<@map_input_name;$i++){
    if($map_input_state[$i] eq "map_input"){
        $space = "input";
        $bits = $map_input_bitrange[$i];
        if($show_infor) { $infor = "//map_input port"; }
        else            { $infor = "";}
        $name = "$map_input_inname[$i];    \n";
        write_file();
    }
}
print OUTFILE ("//------------------ output ----------------------\n");
for($i=0;$i<@oport_array;$i++){
    if($oport_useinfo[$i] eq "output"){
        $space = "output";
        $bits = $oport_bits[$i];
        $name = "$oport_realname[$i];\n";
        write_file();
    }
}

for($i=0;$i<@map_output_name;$i++){
        $space = "output";
        $bits = $map_output_bits[$i];
        if($show_infor) { $infor = "//map output port"; }
        else            { $infor = "";}
        $name = "$map_output_outname[$i];    \n";
        write_file();
}
print OUTFILE "\n";
    


print OUTFILE ("//------------------ wire ----------------------\n");
if($show_infor) { $infor = "//-------------- inner connection ---------------\n"; }
else            { $infor = "";}
print OUTFILE ("$infor");

while(($inner_wirename,$inner_wirebits) = each(%inner_wirebits)){
        $space = "wire";
        $bits = $inner_wirebits;
        $name = "$inner_wirename;\n";
        write_file();
}
#for($i=0;$i<@inner_realname;$i++){
#        $space = "wire";
#        $bits = $inner_bits[$i];
#        $name = "$inner_realname[$i];\n";
#        write_file();
#}

if($show_infor) { $infor = "//-------------- map port ---------------\n"; }
else            { $infor = "";}
print OUTFILE ("$infor");

#for($i=0;$i<@map_oport;$i++){
#    print OUTFILE ("wire    $map_bits[$i]    $map_oport_realname[$i];\n");
#}

while(($key,$value) = each(%map_oport_index)){    
        $space = "wire";
        $bits = $map_bits[$value];
        $name = "$map_oport_realname[$value];\n";
        write_file();
}

print OUTFILE "\n";

for($i=0;$i<@map_output_name;$i++){
    if(!exists $map_oport_index{$map_output_fullname[$i]}){
        $space = "wire";
        $bits = $map_output_wirebits[$i];
        if($show_infor) { $infor = "//map_output port"; }
        else            { $infor = "";}
        $name = "$map_output_realname[$i];    $infor\n";
        write_file();
    }
}

if($show_infor) { $infor = "//-------------- direct write wire begin ---------------\n"; }
else            { $infor = "";}
print OUTFILE ("$infor");
for($i=0;$i<@write_wire;$i++){
    if($show_infor) { $infor = "//write wire"; }
    else            { $infor = "";}
    print OUTFILE ("$write_wire[$i] $infor\n");
}
if($show_infor) { $infor = "//-------------- direct write wire end ---------------\n"; }
else            { $infor = "";}
print OUTFILE ("$infor");
print OUTFILE "\n";


for($i=0;$i<@map_output_name;$i++){
    if($show_infor) { $infor = "//map_output port"; }
    else            { $infor = "";}
    print OUTFILE ("assign   $map_output_outname[$i] = $map_output_realname[$i]$map_output_bitrange[$i];    $infor\n");
}

if($show_infor) { $infor = "//-------------- direct write assign begin ---------------\n"; }
else            { $infor = "";}
print OUTFILE ("$infor");
for($i=0;$i<@write_assign;$i++){
    if($show_infor) { $infor = "//write assign"; }
    else            { $infor = "";}
    print OUTFILE ("$write_assign[$i]    $infor\n");
}
if($show_infor) { $infor = "//-------------- direct write assign end ---------------\n"; }
else            { $infor = "";}
print OUTFILE ("$infor");


print OUTFILE "\n";


foreach $sub (@subinstance_name) {
    print OUTFILE ("$instance_list{$sub} $sub_para{$sub} $sub \(\n");
    print OUTFILE ("`delete comma\n");
    chomp($sub);
    foreach $interport (@$sub) {
        chomp($interport);
        $fullname = "$sub\_$interport";
        if(exists $map_set_name{$fullname}){
            $set_name = $map_set_name{$fullname};
            if($show_infor) { $infor = "//set name"; }
            else            { $infor = "";}
            print  OUTFILE ("    ,\.$interport \($set_name\)   $infor\n");
        }
        elsif(exists $map_input_namebits_sub{$fullname}){ 
            if($show_infor) { $infor = "//top input"; }
            else            { $infor = "";}
            print  OUTFILE ("    ,\.$interport \($map_input_namebits_sub{$fullname}\)   $infor\n");           
        }
        elsif(exists $map_iport_index{$fullname}){
            $match = $map_iport_index{$fullname};
            if($show_infor) { $infor = "//mapped in port"; }
            else            { $infor = "";}
            print  OUTFILE ("    ,\.$interport \($map_oport_realname[$match]$map_oport_bitrange[$match]\)   $infor\n");
        }
        elsif(exists $oport_index{$fullname}){
            $match = $oport_index{$fullname};
            if($show_infor) { $infor = "//$oport_useinfo[$match]"; }
            else            { $infor = "";}
            print  OUTFILE ("    ,\.$interport \($oport_realname[$match]\)   $infor\n");           
        }
        else{
            $match = $iport_index{$fullname};
            if($show_infor) { $infor = "//$iport_useinfo[$match]"; }
            else            { $infor = "";}
            print  OUTFILE ("    ,\.$interport \($iport_realname[$match]\)   $infor\n");           
        }
#        elsif(exists $iport_index{$fullname}){
#            $match = $iport_index{$fullname};
#            $infor = $iport_useinfo[$match]; 
#            print  OUTFILE ("    \.$interport \($iport_realname[$match]\),   //$infor\n");           
#        }
#        else{
#            $match = $oport_index{$fullname};
#            $infor = $oport_useinfo[$match]; 
#            print  OUTFILE ("    \.$interport \($oport_realname[$match]\),   //$infor\n");           
#        }
    }
    print OUTFILE ("\);");
    print OUTFILE "\n\n";
}

print OUTFILE ("endmodule");

close(SUBFILE);
close(FILEI);
close(OUTFILE);



####################        $top.v      ###################
if (open(FILEI, "$top.v.tmp")) {
    print "Remove comma! \n"
}
else {
    die ("Cannot open the file! \n");
}

if (open(OUTFILE1, ">$top.v")) {
    print "Open file $top.v to write! \n"
}
else {
    die ("Cannot open the file $top.v! \n");
}

@final = <FILEI>;
$del_comma_flag = 0;
foreach $final_line (@final) {
    if(($del_comma_flag == 1) && ($final_line =~ /\,/)) {
        $final_line =~ s/\,/ /;
        $del_comma_flag = 0;
    }   
    if($final_line =~ /`delete comma/) {
        $del_comma_flag = 1;
        $final_line = "";
    }
    elsif($final_line =~ /`delete /){
        $final_line = "";
    }
    print OUTFILE1 $final_line;
}

system("rm $top.v.tmp");
close(FILEI);
close(OUTFILE1);




##################    print information table################
select(\*STDOUT);
$print_iport_array  = 1;
$print_oport_array  = 1;
$print_map_iport    = 1;
$print_map_oport    = 1;
$print_map_input    = 1;
$print_map_output   = 1;
format STDOUT=
@<<<<<<<<<<<< @<<<<<<<<<<<<<<<< @<<<<<<<<<<<<< @<<<<<<<<<< @<<<<<<<<<<<<<< @<<<<<<<<<<<<<<<<<<<<<<<<<< @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< @<<<<<<<<<<<<<<<<<
$pt1,$pt2,$pt3,$pt4,$pt5,$pt6,$pt7,$pt8
.
print("\n##################    print information table################\n");
if($print_iport_array == 1){
    $pt1="ARRAY";$pt2="NAME";$pt3="INSTANCE";$pt4="BITS";
    $pt5="USEINFO";$pt6="FULLNAME";$pt7="REALNAME";$pt8="\n";
    write;
    print("-"x100,"\n");
    for($i=0;$i<@iport_array;$i++){
        $pt1="in[$i]";$pt2=$iport_array[$i];$pt3=$iport_instance[$i];$pt4=$iport_bits[$i];
        $pt5=$iport_useinfo[$i];$pt6=$iport_fullname[$i];$pt7=$iport_realname[$i];$pt8="\n";
        write;
    }
    print("-"x100,"\n");
}
if($print_oport_array == 1){
    $pt1="ARRAY";$pt2="NAME";$pt3="INSTANCE";$pt4="BITS";
    $pt5="USEINFO";$pt6="FULLNAME";$pt7="REALNAME";$pt8="\n";
    write;
    print("-"x100,"\n");
    for($i=0;$i<@oport_array;$i++){
        $pt1="out[$i]";$pt2=$oport_array[$i];$pt3=$oport_instance[$i];$pt4=$oport_bits[$i];
        $pt5=$oport_useinfo[$i];$pt6=$oport_fullname[$i];$pt7=$oport_realname[$i];$pt8="\n";
        write;
    }
    print("-"x100,"\n");
}

if($print_map_iport == 1){
    $pt1="ARRAY";$pt2="NAME";$pt3="INSTANCE";$pt4="BITS";
    $pt5="FULLNAME";$pt6="REALNAME";$pt7="";$pt8="\n";
    write;
    print("-"x100,"\n");
    for($i=0;$i<@map_iport_name;$i++){
        $pt1="map in[$i]";$pt2=$map_iport_name[$i];$pt3=$map_iport_instance[$i];$pt4=$map_iport_bitrange[$i];
        $pt5=$map_iport_fullname[$i];$pt6=$map_iport_realname[$i];$pt7="";$pt8="\n";
        write;
    }
    print("-"x100,"\n");
}
if($print_map_oport == 1){
    $pt1="ARRAY";$pt2="NAME";$pt3="INSTANCE";$pt4="BITS";
    $pt5="FULLNAME";$pt6="REALNAME";$pt7="";$pt8="\n";
    write;
    print("-"x100,"\n");
    for($i=0;$i<@map_oport_name;$i++){
        $pt1="map out[$i]";$pt2=$map_oport_name[$i];$pt3=$map_oport_instance[$i];$pt4=$map_oport_bitrange[$i];
        $pt5=$map_oport_fullname[$i];$pt6=$map_oport_realname[$i];$pt7="";$pt8="\n";
        write;
    }
    print("-"x100,"\n");
}
if($print_map_input == 1){
    $pt1="ARRAY";$pt2="NAME";$pt3="INSTANCE";$pt4="BITS";
    $pt5="FULLNAME";$pt6="INNAME";$pt7="STATE";$pt8="\n";
    write;
    print("-"x100,"\n");
    for($i=0;$i<@map_input_name;$i++){
        $pt1="map output[$i]";$pt2=$map_input_name[$i];$pt3=$map_input_instance[$i];$pt4=$map_input_bitrange[$i];
        $pt5=$map_input_fullname[$i];$pt6=$map_input_inname[$i];$pt7="$map_input_state[$i]";$pt8="\n";
        write;
    }
    print("-"x100,"\n");
}
if($print_map_output == 1){
    $pt1="ARRAY";$pt2="NAME";$pt3="INSTANCE";$pt4="BITS";
    $pt5="FULLNAME";$pt6="OUTNAME";$pt7="";$pt8="\n";
    write;
    print("-"x100,"\n");
    for($i=0;$i<@map_output_name;$i++){
        $pt1="map output[$i]";$pt2=$map_output_name[$i];$pt3=$map_output_instance[$i];$pt4=$map_output_bitrange[$i];
        $pt5=$map_output_fullname[$i];$pt6=$map_output_outname[$i];$pt7="";$pt8="\n";
        write;
    }
    print("-"x100,"\n");
}


#while(($key,$value) = each(%instance_list)){
#    print("\instance_list key = $key ,value = $value \n");
#}
#while(($key,$value) = each(%instance_times)){
#    print("\instance_times key = $key ,value = $value \n");
#}
#while(($key,$value) = each(%iport_index)){
#    print("\$iport key = $key ,value = $value \n");
#}
#while(($key,$value) = each(%oport_index)){
#    print("\$oport key = $key ,value = $value \n");
#}
#while(($key,$value) = each(%map_oport_index)){
#    print("\map_oport_index key = $key ,value = $value \n");
#}

print "THE END! \n********************\n";
