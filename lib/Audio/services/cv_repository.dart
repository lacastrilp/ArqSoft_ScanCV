import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/cv_model.dart';
import '../models/cv_section_model.dart';
import '../models/cv_field_model.dart';

class CVRepository {
  final SupabaseClient client;

  CVRepository(this.client);

  Future<void> createCV(CV cv) async {
    await client.from('cv').insert(cv.toJson());
  }

  Future<List<CV>> getCVs(String ownerId) async {
    final response = await client
        .from('cv')
        .select('*, sections(*, fields(*))')
        .eq('ownerId', ownerId);
    return (response as List<dynamic>)
        .map((json) => CV.fromJson(json))
        .toList();
  }

  Future<void> updateCV(CV cv) async {
    await client.from('cv').update(cv.toJson()).eq('id', cv.id);
  }

  Future<void> deleteCV(String cvId) async {
    await client.from('cv').delete().eq('id', cvId);
  }

  Future<void> addSection(String cvId, CVSection section) async {
    await client.from('sections').insert({
      ...section.toJson(),
      'cvId': cvId,
    });
  }

  Future<void> addField(String sectionId, CVField field) async {
    await client.from('fields').insert({
      ...field.toJson(),
      'sectionId': sectionId,
    });
  }
}
