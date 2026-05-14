class School {
  const School({
    required this.id,
    required this.name,
    required this.shortName,
    required this.supportsAcademicImport,
    required this.supportsImageRecognition,
  });

  final String id;
  final String name;
  final String shortName;
  final bool supportsAcademicImport;
  final bool supportsImageRecognition;
}

class SchoolCatalog {
  const SchoolCatalog._();

  static const jit = School(
    id: 'jit',
    name: '金陵科技学院',
    shortName: 'JIT',
    supportsAcademicImport: true,
    supportsImageRecognition: false,
  );

  static const schools = <School>[jit];

  static School? byId(String id) {
    for (final school in schools) {
      if (school.id == id) {
        return school;
      }
    }
    return null;
  }
}
