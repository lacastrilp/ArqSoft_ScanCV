import '../domain/models/cv_section_model.dart';

final List<CVSection> cvSections = [
  CVSection(
    id: 'personal_info',
    title: 'Información Personal',
    description: 'Cuéntanos sobre ti: nombre completo, dirección, teléfono, correo, nacionalidad, fecha de nacimiento, estado civil, redes sociales y portafolio.',
    fields: ['Nombre completo', 'Dirección', 'Teléfono', 'Correo', 'Nacionalidad', 'Fecha de nacimiento', 'Estado civil', 'LinkedIn', 'GitHub', 'Portafolio'],
  ),
  CVSection(
    id: 'professional_profile',
    title: 'Perfil Profesional',
    description: 'Resume quién eres, qué haces y cuál es tu enfoque profesional. Esta es tu oportunidad para destacar.',
    fields: ['Resumen profesional'],
  ),
  CVSection(
    id: 'education',
    title: 'Educación',
    description: 'Menciona tus estudios realizados, instituciones, fechas y títulos obtenidos, comenzando por los más recientes.',
    fields: ['Estudios', 'Instituciones', 'Fechas', 'Títulos'],
  ),
  CVSection(
    id: 'work_experience',
    title: 'Experiencia Laboral',
    description: 'Detalla las empresas donde has trabajado, cargos, funciones, logros y duración, comenzando por la más reciente.',
    fields: ['Empresas', 'Cargos', 'Funciones', 'Logros', 'Duración'],
  ),
  CVSection(
    id: 'skills',
    title: 'Habilidades y Certificaciones',
    description: 'Enumera tus habilidades técnicas, blandas y cualquier certificación relevante que hayas obtenido.',
    fields: ['Habilidades técnicas', 'Habilidades blandas', 'Certificaciones'],
  ),
  CVSection(
    id: 'languages',
    title: 'Idiomas y Otros Logros',
    description: 'Menciona los idiomas que hablas, publicaciones, premios, voluntariados, experiencia internacional, permisos o licencias.',
    fields: ['Idiomas', 'Publicaciones', 'Premios', 'Voluntariados', 'Experiencia internacional', 'Permisos/Licencias'],
  ),
  CVSection(
    id: 'references',
    title: 'Referencias y Detalles Adicionales',
    description: 'Incluye referencias laborales/personales, expectativas laborales, contacto de emergencia y disponibilidad para entrevistas.',
    fields: ['Referencias laborales', 'Referencias personales', 'Expectativas laborales', 'Contacto de emergencia', 'Disponibilidad'],
  ),
];