BEGIN{
print "START"; 
CNT_30 = 0;
CNT_50 = 0;
CNT_100 = 0;
CNT_200 = 0;
CNT_300 = 0;
CNT_400 = 0;
CNT_500 = 0;
CNT_600 = 0;
TOTAL = 0;
}

{
        if(/tag=107/)
        {
                ++TOTAL;
                sub(/^.*etime=/,"",$0);
                time = ( $0 * 1000 );
                if( time < 30 ){
                        ++CNT_30;
                }else if( 30 <= time && time < 50 ){
                        ++CNT_50;
                }else if( 50 <= time && time < 100 ){
                        ++CNT_50;
                }else if( 100 <= time && time < 200 ){
                        ++CNT_100;
                }else if( 200 <= time && time < 300 ){
                        ++CNT_200;
                }else if( 300 <= time && time < 400 ){
                        ++CNT_300;
                }else if( 400 <= time && time < 500 ){
                        ++CNT_400;
                }else if( 500 <= time && time < 600 ){
                        ++CNT_500;
                }   
        }
}

END{
        print "END";
        printf "%-10s\t %-10s\t %-10s\t %-10s\t %-10s\t %-10s\t %-10s\t %-10s\t %-10s\n", "CNT_30", "CNT_50", "CNT_100", "CNT_200", "CNT_300", "CNT_400", "CNT_500", "CNT_600", "TOTAL";
        printf "%-10s\t %-10s\t %-10s\t %-10s\t %-10s\t %-10s\t %-10s\t %-10s\t %-10s\n", CNT_30, CNT_50, CNT_100, CNT_200, CNT_300, CNT_400, CNT_500, CNT_600, TOTAL;
}