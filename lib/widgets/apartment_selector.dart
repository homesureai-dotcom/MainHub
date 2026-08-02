import 'package:flutter/material.dart';
import '../data/sample_data.dart';
import '../models/apartment.dart';

class ApartmentSelector extends StatelessWidget {
  final Apartment selectedApartment;
  final ValueChanged<Apartment> onChanged;

  const ApartmentSelector({
    super.key,
    required this.selectedApartment,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<Apartment>(
      initialValue: selectedApartment,
      decoration: InputDecoration(
        labelText: "Select Apartment",
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
        ),
      ),
      items: apartments.map((apartment) {
        return DropdownMenuItem(
          value: apartment,
          child: Text(apartment.projectName),
        );
      }).toList(),
      onChanged: (value) {
        if (value != null) {
          onChanged(value);
        }
      },
    );
  }
}