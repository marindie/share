BEGIN{
    IGNORECASE=1
}
{
    if(/Executing Statement/){
        print "=========================================";
        gsub(/^.*?Statement: */,"");
        text = $0;
        while(getline>0){
            if(/Parameters/){
                gsub(/^.*?Parameters: \[/,"");
                gsub(/]/,"");
                param = $0;
                cnt = split($0,arr,",");
                for( i=1 ; i <= cnt ; i++){
                                        temp = "'"arr[i]"'";
                                        gsub(/ /,"",temp);
                    sub("?",temp,text);
                }
                text = text ";"
                break;
            }
        }
        print text;
        print "=========================================\n";
    }
}