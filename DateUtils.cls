public class DateUtils{

  	public static final Map<String,Integer> dayOfWeekNameMap = new Map<String,Integer>{  'SUNDAY' => 0,
	'MONDAY' => 1,
	'TUESDAY' => 2,
	'WEDNESDAY' => 3,
	'THURSDAY' => 4,
	'FRIDAY' => 5,
	'SATURDAY' => 6};
    
  	public static final Map<Integer,String> dayOfWeekNumberMap = new Map<Integer,String>{  0 => 'Sunday',
       1 => 'Monday',
       2 => 'Tuesday',
       3 => 'Wednesday',
       4 => 'Thursday',
       5 => 'Friday',
       6 => 'Saturday'};
    public static final Integer SUNDAY = 0;
    public static final Integer MONDAY = 1;
    public static final Integer TUESDAY = 2;
    public static final Integer WEDNESDAY = 3;
    public static final Integer THURSDAY = 4;
    public static final Integer FRIDAY = 5;
    public static final Integer SATURDAY = 6;
    
    public static final Date FIRSTDATE1900 = Date.newInstance(1900, 1, 7);
    
    public static Integer getDayOfWeekNumber(String dayName) {
        if(dayOfWeekNameMap.containsKey(dayName.toUpperCase())) {
            return dayOfWeekNameMap.get(dayName.toUpperCase());
        }
        return -1;
    }

    public static Integer getDayOfWeekNumber(Date inDate) {
        Integer dateDiff = FIRSTDATE1900.daysBetween(inDate);
        return Math.mod(dateDiff, 7);        
    }

    public static String getDayOfWeekName(Date inDate) {
        return getDayOfWeekName(getDayOfWeekNumber(inDate));
    }

    public static String getDayOfWeekName(Integer num) {
        System.debug('BEGIN: getDayOfWeekName');
        String weekName = null;
        System.debug('num = ' + num);
        if(num <= 6 && num >= 0) {
            System.debug('num is <=6 and >=0');
            weekName = dayOfWeekNumberMap.get(num);         
        }
        System.debug('weekName = ' + weekName);
        System.debug('END: getDayOfWeekName');
        return weekName;
    }

    public static Boolean isSunday(Date inDate) {
        Integer dateDiff = FIRSTDATE1900.daysBetween(inDate);
        return Math.mod(dateDiff, 7) == 0;
    }

    public static Boolean isSaturday(Date inDate) {
        Integer dateDiff = FIRSTDATE1900.daysBetween(inDate);
        return Math.mod(dateDiff, 7) == 6;
    }

	public static Boolean isWeekend(Date inDate) {
		return isSunday(inDate) || isSaturday(inDate);
	}
	
    //If the date passed in is a Sunday this will return that date.
    public static Date getCurrentOrPriorSunday(Date inDate) {
        if(DateUtils.isSunday(inDate)) {
            return inDate;
        }
        Date sundayOrMonday = inDate.toStartOfWeek();
        //If it's a Sunday we're done
        if(DateUtils.isSunday(sundayOrMonday)) {
            return sundayOrMonday;
        } else { //Else it's a Monday so subtract one day from it.
            return sundayOrMonday.addDays(-1);
        }
    }
   
    //If the date passed in is a Saturday this will return that date.
    public static Date getCurrentOrNextSaturday(Date inDate) {
        if(DateUtils.isSaturday(inDate)) {
            return inDate;
        }
        Date sundayOrMonday = inDate.toStartOfWeek();
        //If it's a Sunday we add 6 days and we're at Saturday
        if(DateUtils.isSunday(sundayOrMonday)) {
            return sundayOrMonday.addDays(6);
        } else { //Else it's a Monday so add 5 days and we're at Saturday
            return sundayOrMonday.addDays(5);
        }
    }
   
    /* This method takes the standard date format masks
     * Letter  Date or Time Component  Presentation  Examples  
       http://download.oracle.com/javase/1.4.2/docs/api/java/text/SimpleDateFormat.html
		G  Era designator  Text  AD  
		y  Year  Year  1996; 96  
		M  Month in year  Month  July; Jul; 07  
		w  Week in year  Number  27  
		W  Week in month  Number  2  
		D  Day in year  Number  189  
		d  Day in month  Number  10  
		F  Day of week in month  Number  2  
		E  Day in week  Text  Tuesday; Tue  
		a  Am/pm marker  Text  PM  
		H  Hour in day (0-23)  Number  0  
		k  Hour in day (1-24)  Number  24  
		K  Hour in am/pm (0-11)  Number  0  
		h  Hour in am/pm (1-12)  Number  12  
		m  Minute in hour  Number  30  
		s  Second in minute  Number  55  
		S  Millisecond  Number  978  
		z  Time zone  General time zone  Pacific Standard Time; PST; GMT-08:00  
		Z  Time zone  RFC 822 time zone  -0800      
	    
	    Common formats include:
	    'yyyy-MM-dd'
	    'MM/dd/yyyy'
	    'MM/dd'
     */
    public static String formatDate(Date thisDay, String formatMask) {
    	if(thisDay == null) return '';
    	Time t = Time.newInstance(0, 0, 0, 0);
    	DateTime dt = DateTime.newInstance(thisDay, t);
    	return dt.format(formatMask);
    }
   
    //Returns the day padded with a 0 (e.g. January 4th is 04 not 4)
    public static String getDay(Date inDate) {
        String dd = '';
        if(inDate.day() < 10) {
            dd = '0' + inDate.day().format();
        } else {
            dd = inDate.day().format();
        }
        return dd;
    }
   
	public static String getDay(Datetime inDatetime) {
		return getDay(inDatetime.Date());
	}
	
    //Returns the month padded with a 0 (e.g. January is 01 not 1)
    public static String getMonth(Date inDate) {
        String mm = '';
        if(inDate.month() < 10) {
            mm = '0' + inDate.month().format();
        } else {
            mm = inDate.month().format();
        }
        return mm;
    }
	
	public static String getMonth(Datetime inDatetime) {
		return getMonth(inDatetime.Date());
	}

}