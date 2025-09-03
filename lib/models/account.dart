enum Year { year1, year2, year3, year4 }

enum Faculty {
  computerEngineering(title: "วิศวกรรมคอมพิวเตอร์"),
  electricalEngineering(title: "วิศวกรรมไฟฟ้า"),
  mechanicalEngineering(title: "วิศวกรรมเครื่องกล"),
  civilEngineering(title: "วิศวกรรมโยธา"),
  chemicalEngineering(title: "วิศวกรรมเคมี"),
  computerScience(title: "วิทยาการคอมพิวเตอร์"),
  informationTechnology(title: "เทคโนโลยีสารสนเทศ"),
  architecture(title: "สถาปัตยกรรม"),
  business(title: "บริหารธุรกิจ"),
  economics(title: "เศรษฐศาสตร์"),
  law(title: "นิติศาสตร์"),
  medicine(title: "แพทยศาสตร์"),
  nursing(title: "พยาบาลศาสตร์"),
  pharmacy(title: "เภสัชศาสตร์"),
  publicHealth(title: "สาธารณสุขศาสตร์"),
  science(title: "วิทยาศาสตร์"),
  education(title: "ครุศาสตร์/ศึกษาศาสตร์"),
  humanities(title: "มนุษยศาสตร์"),
  socialSciences(title: "สังคมศาสตร์"),
  agriculture(title: "เกษตรศาสตร์"),
  fisheries(title: "ประมง"),
  forestry(title: "วนศาสตร์"),
  politicalScience(title: "รัฐศาสตร์"),
  fineArts(title: "ศิลปกรรมศาสตร์"),
  music(title: "ดุริยางคศิลป์"),
  sportsScience(title: "วิทยาศาสตร์การกีฬา"),
  other(title: "อื่นๆ");

  const Faculty({required this.title});
  final String title;
}

class User {
  final String email;
  final String password;
  final String firstName;
  final String lastName;
  final Year year;
  final String group;
  final int age;
  final Faculty faculty;
  final String role = "user";

  User({
    required this.email,
    required this.password,
    required this.firstName,
    required this.lastName,
    required this.year,
    required this.group,
    required this.age,
    required this.faculty,
  });
}
