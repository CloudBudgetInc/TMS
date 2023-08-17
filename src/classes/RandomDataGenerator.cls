/* **************************************************************************
* Helper Class: RandomDataGenerator
* Created by Jesus Varela, 10-23-2017
*
* Purpose/Methods:
* - generate random data for unit tests
* 
* Modifications:
* - {DevName}, {MM/DD/YYYY} - {Description of changes made post deployment to client}
*
************************************************************************** */
@isTest
public class RandomDataGenerator 
{
    private static List<String> firstNames = new List<String> {'Lena','Doris','Louis','Michael','Ann','Carolyn','Faye','Peter',
                'Natasha','Roger','Joe','Fred','Dorothy','Irma','Shawn','Sheryl','Clara',
                'Frank','Jacquelyn','Louis','Jonathan','Ralph','Vincent','Emma','Bobby',
                'Gerald','Curtis','Phillip','Jeff','Paul','Linda','Candace','Juan','Genevieve',
                'Sandra','Lucille','Kirkland','Jacob','Patrick','Lawrence','Geraldine','Louis',
                'Sherri','Angie','Jeannette','Andrew','Cassandra','Claudia','Travis','Joanna',
                'Anthony','Aaron','Rodney','Chris','Todd','Vidal','Dolores','Debra','Joyce',
                'Hilda','Shelia','Christopher','Craig','Carl','Velma','David','Mike','Arthur',
                'Jeanette','Nellie','Manuel','Christina','Peter','David','Jimmy','Harry','Olga',
                'Carl','Molly','Richard','Bertha','Edward','Stephen','Janice','Harold','Ruby',
                'Eunice','Johnny','Edward','Sabrina','Hannah','Ruby','Todd','Bryan','Dolores',
                'Gregory','Samantha','Albert','Alan','Rachel','Eric','Bernice','Marvin','Justin',
                'Kenneth','Naomi','Donald','Raymond','Hannah','Andrew','Jo','Cassandra','William',
                'Joshua','David','Kenneth','Billy'};

    private static List<String> lastNames = new List<String> {'Mahaffey','Kinsella','Stanfield','Tsosie','Troxell','Shilling','Land',
                'Bigler','Kastner','Gwinn','Smalls','Burroughs','Broderick','Yingling','Feder','Ha',
                'New','Floyd','Lefler','Ivey','Cardinal','Tenney','Seger','Mcginn','Mendez','Matteson',
                'Mcmaster','Frisbie','Mcelroy','Ayotte','Everson','Lunsford','Ulrich','Kujawa','Eddins',
                'Palmer','Sines','Palomo','Denison','Babbitt','Santoro','Kellerman','Fortunato',
                'Blake','Salter','Carrington','Squires','Mares','Arbogast','Mcnew','Hairston','Dowden',
                'Hadden','Pack','Martindale','Ngo','Rao','Erdman','Baltazar','Byers','Deitz','Mayle',
                'Condon','Robertson','Wilborn','Ramsey','Mckoy','Corley','Snelling','Wilford','Nevins',
                'Whitacre','Pettiford','Henning','Bidwell','Chiles','Desjardins','Stanton','Kent',
                'Vanwinkle','Bartholomew','English','Farina','Zook','Hyman','Correll','Elson','Speaks',
                'Field','Kushner','Paulin','Driggers','Clanton','Paxton','Hinojosa','Healy','Woodall',
                'Busse','Kingery','Ching','Santacruz','Tyler','Chong','Galindo','Kingston','Pelton',
                'Kyser','Eakin','Fricke','Hillard','Rolfe','Rafferty','Grow','Smart','Held'};
                
    private static List<String> cities = new List<String> {'Atlanta','Norcross', 'Mission Viejo', 'Portola Hills', 'Los Angeles'
                , 'Birmingham', 'Newnan', 'Moreland','West Clarkvale','Daytown','Campbury'
                ,'Hilridge','Bayview','Shakerchester','Hartvale','Huntshart','Stoneplain Estates'
                ,'Portburgh','Bridgewell','Cape Plumgate','Elmmill','Fairville','Glenshore'
                ,'Greater Millley','Hollyhurst','Lake Harborwell','Lower Countrywood'
                ,'Mapleside Terrace','Mount Oakbrook','New Whiteshore','North Riverridge'
                ,'Northmount Heights','Orchard Estates','Orchardgrove Bridge','Point Glenwell'
                ,'Point Lakebourne','Point Pleasanthill','Rosewood','Sheffield Farms','Sheffield Gate'
                ,'Silvervale Chase','South Elmridge','Whiteville','Ashmoss','Belmont Grange'
                ,'Cape Glenview','Devon Village','Downs Trails','Downstree Point','East Chase'
                ,'East Countrygrove','Greater Peachmill','Mist Square','Mount Westmill','North Crossing'
                ,'Northwood','Orchardbrook Manor','Orchardmill','Oxford Creek','Oxford Towers'
                ,'Point Fieldcrest','Radcliffe Chase','Sea Acres','Silver Downs','Spring Acres'
                ,'Westborough','Woodfair','Woodley Creek'};

    private static List<String> states = new List<String> {'AL','AK','AZ','AR','CA','CO','CT','DE','DC','FL','GA','HI','ID',
                'IL','IN','IA','KS','KY','LA','ME','MD','MA','MI','MN','MS','MO',
                'MT','NE','NV','NH','NJ','NM','NY','NC','ND','OH','OK','OR','PA',
                'RI','SC','SD','TN','TX','UT','VT','VA','WA','WV','WI','WY'};
                
    private static List<String> gender = new List<String> {'Male','Female','Other','Prefer not to say'};
    
    private static List<String> refereeTypes = new List<String> {'Assessment of Research Capacity'};

    private static List<String> streets = new List<String> {'Elm', 'Main', 'Oak', 'Peachtree', 'Akins', 'Teasley', 'Techwood', 'Las Flores'};
    
    private static List<String> streetTypes = new List<String> {'Rd.', 'Dr.','St.', 'Lane', 'Ave', 'Circle', 'Trace', 'Trail', 'Blv'};

    private static String[] alphaNumericCharacters = new String[]{'0','1','2','3','4','5','6','7','8','9'
            ,'a','b','c','d','e','f','g','h','i','j'
            ,'k','l','m','n','o','p','q','r','s','t'
            ,'u','v','w','x','y','z'};

    public static string getFirstName()
    {
        Integer index = Math.Mod(RandomInt(firstNames.size()), firstNames.size());
        return firstNames[index];
    }

    public static string getLastName()
    {
        Integer index = Math.Mod(RandomInt(lastNames.size()), lastNames.size());
        return lastNames[index];
    }

    public static String getEmailAddress()
    {
        String addr = getFirstName() + '.' + getLastName() + '@randomemailtest.com';
        return addr;
    }

    public static string getZipCode()
    {
        String zip = '';
        for (integer i = 0 ; i < 5 ; i++) {
            Integer digit = RandomInt(9);
            zip += '' + digit;
        }

        return zip;
    }

    public static string getRandomNumber(Integer digits)
    {
        String zip = '';
        for (integer i = 0 ; i < digits ; i++) {
            Integer digit = RandomInt(9);
            zip += '' + digit;
        }

        return zip;
    }

    public static string getCity() 
    {
        Integer index = RandomInt(cities.size());
        return cities[index];
    }

    private static string getStreetName()
    {
        Integer index = RandomInt(streets.size());
        return streets[index];
    }

    private static string getStreetType() 
    {

        Integer index = RandomInt(streetTypes.size());
        return streetTypes[index];
    }

    public static string getStreetAddress() 
    {
        integer streetNumber = RandomInt(10000) + 1;
        return '' + streetNumber + ' ' + getStreetName() + ' ' + getStreetType();
    }

    public static string getFormattedPhoneNumber()
    {
        return PhoneFormatter(getPhoneNumber());
    }

    public static string getPhoneNumber()
    {
        String PhoneNumber = '';
        for (integer i = 0 ; i < 10 ; i++) {
            Integer digit = RandomInt(9);

            // Phone numbers cannot begin with a 0 or 1
            if (i == 0 && (digit <= 1)){
                i--;
            } else {
                PhoneNumber += '' + digit;
            }
        }
        return PhoneNumber;
    }

    public static string getStateCode() 
    {
        Integer index = RandomInt(states.size());
        return states[index];
    }
    
    public static string getGender() 
    {
        Integer index = RandomInt(gender.size());
        return gender[index];
    }
    
    public static string getRefereeType() 
    {
        Integer index = RandomInt(refereeTypes.size());
        return refereeTypes[index];
    }

    public static string getCompanyName() 
    {
        string company = '';
        integer format = RandomInt(7);
        if (format == 0) {
            company = getLastName() + ' Limited';
        } else if (format == 1) {
            company = getCity() + ' Corporate';
        } else if (format == 2) {
            company = 'House of ' + getCity();
        } else if (format == 3) {
            company = getLastName() + ' and ' + getLastName() + ' Brothers';
        } else if (format == 4) {
            company = getCity() + ' Best';
        } else if (format == 5) {
            company = getLastName() + ' Estate';
        } else if (format == 6) {
            company = getCity() + ' Properties';
        } else if (format == 7) {
            company = getFirstName() + ' ' + getLastName() + ' Rentals';
        }
        return company;
    }

    public static Integer RandomInt(Integer maxValue)
    {
        Integer index = Math.Mod(Math.Round((Math.Random() * maxValue)),maxValue);
        return index;
    }

    public static string getAlphaNumericString(Integer length)
    {
        string AlphaNumericString = '';
        for (integer i = 0 ; i < length ; i++) {
            Integer index = RandomInt(alphaNumericCharacters.size());
            AlphaNumericString += alphaNumericCharacters[index];
        }
        return AlphaNumericString;
    }

    private static string PhoneFormatter(string phoneNumber)
    {
        if (phoneNumber == null) return null;
        string formatted = '';
        string digitsOnly = '';
        for (integer i = 0 ; i < phoneNumber.length() ; i++){
            string current = phoneNumber.substring(i, i+1);
            if (Pattern.matches('\\d',current)) {
                digitsOnly += current;
            }
        }

        if (digitsOnly.length() != 10)
        {
            return phoneNumber;
        }

        // We aren't checking the length because it's being checked in the validation rule.
        // This is just to format unformatted phone numbers.
        formatted = '(' + digitsOnly.substring(0,3) + ') ' + digitsOnly.substring(3,6) +  '-' + digitsOnly.substring(6);
        return formatted;
    }

    
}