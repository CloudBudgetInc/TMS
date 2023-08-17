public virtual class test_Data 
{
    public Account acct { get; set; }
    
    public Opportunity opp1 { get; set; } 
    public Opportunity opp2 { get; set; } 
    
    public Lead lead1 { get; set; } 
    public Lead lead2 { get; set; } 
    
    public Contact person1 { get; set; }
    public Contact person2 { get; set; }
    
    public Task task1a { get; set; }
    public Task task1b { get; set; }
    public Task task1c { get; set; }
    public Task task2a { get; set; }
    public Task task2b { get; set; }
    public Task task2c { get; set; }

    public test_Data() 
    {
        initialize();
    }

    public void initialize()
    {
        createAccount();
        createContacts();
        createOpportunity1Data();
        createOpportunity2Data();
    }

    private void createAccount()
    {
        acct = new Account();
        acct.Name = 'TEST ACCT';
        insert acct;
    }

    private void createContacts()
    {
        person1 = createContact('John', 'Smith', 'johnsmith@someplace.com', '9995551212');
        insert person1;

        person2 = createContact('Jane', 'Smith', 'janesmith@someplace.com', '9995551414');
        insert person2;
    }

    private void createOpportunity1Data()
    {
        opp1 = createOpportunity('TEST OPP 1');
        insert opp1;

        task1a = createTask('TEST SUBJECT 1', Date.today().addDays(-1), opp1.Id);
        task1b = createTask('TEST SUBJECT 1', Date.today().addDays(1), opp1.Id);
        task1c = createTask('TEST SUBJECT 1', Date.today().addDays(3), opp1.Id);

        insert new List<Task>{ task1a, task1b, task1c };
    }

    private void createOpportunity2Data()
    {
        opp2 = createOpportunity('TEST OPP 2');
        insert opp2;

        task2a = createTask('TEST SUBJECT 2', Date.today().addDays(-1), opp2.Id);
        task2b = createTask('TEST SUBJECT 2', Date.today().addDays(1), opp2.Id);
        task2c = createTask('TEST SUBJECT 2', Date.today().addDays(3), opp2.Id);

        insert new List<Task>{ task2a, task2b, task2c };
    }

    public Contact createContact(String firstName, String lastName, String email, String phone)
    {
        Contact cont = new Contact();
        cont.FirstName = firstName;
        cont.LastName = lastName;
        cont.Email = email;
        cont.Phone = phone;
        return cont;
    }

    public Lead createLead(String name)
    {
        Lead newlead = new Lead();
        newlead.LastName = 'Smith';
        newlead.Company = 'ACME';
        return newlead;
    }

    public Opportunity createOpportunity(String name)
    {
        Opportunity opp = new Opportunity();
        opp.Name = name;
        opp.StageName = '1.2 Initial Discussion';
        opp.CloseDate = Date.today().addDays(90);
        return opp;
    }

    public Task createTask(String subject, Date activityDate, Id whatId)
    {
        Task newtask = new Task();
        newtask.Subject = subject;
        newtask.ActivityDate = activityDate;
        newtask.WhatId = whatId;
        newtask.OwnerId = UserInfo.getUserId();
        newTask.WhoId = person1.Id;
        newTask.Status = 'Not Started';
        return newtask;
    }
}