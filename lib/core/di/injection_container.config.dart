// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;
import 'package:silo_monitoring_mobile/core/services/auth_storage_service.dart'
    as _i439;
import 'package:silo_monitoring_mobile/presentation/blocs/auth/auth_bloc.dart'
    as _i834;

extension GetItInjectableX on _i174.GetIt {
// initializes the registration of main-scope dependencies inside of GetIt
  _i174.GetIt init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) {
    final gh = _i526.GetItHelper(
      this,
      environment,
      environmentFilter,
    );
    gh.factory<_i439.AuthStorageService>(() => _i439.AuthStorageService());
    gh.factory<_i834.AuthBloc>(
        () => _i834.AuthBloc(gh<_i439.AuthStorageService>()));
    return this;
  }
}
