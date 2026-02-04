import 'dart:convert';
import 'dart:io';

void main(List<String> args) async {
  if (args.isEmpty) {
    print('Usage: dart run test/fixtures/record_fixture.dart <ICO>');
    exit(1);
  }

  final ico = args[0];
  final url = Uri.parse('https://icoatlas.sk/api/company/$ico');
  print('Fetching data from $url...');

  final client = HttpClient();

  try {
    final request = await client.getUrl(url);
    final response = await request.close();

    if (response.statusCode != 200) {
      print('Failed to fetch data. Status code: ${response.statusCode}');
      exit(1);
    }

    final responseBody = await response.transform(utf8.decoder).join();
    final json = jsonDecode(responseBody);

    // Format JSON
    final formattedJson = const JsonEncoder.withIndent('  ').convert(json);

    final file = File('test/fixtures/ico_$ico.json');
    await file.writeAsString(formattedJson);

    print('Fixture saved to ${file.path}');
  } catch (e) {
    print('Error: $e');
    exit(1);
  } finally {
    client.close();
  }
}
