# Retilda App Architecture

The app now has a clean-architecture target structure for new and migrated
features:

```text
lib/
  core/
    config/       App/environment configuration
    network/      Shared API client and network providers
    security/     Session and secure token storage
    theme/        App-wide visual system
    web/          Safe webview wrappers
  features/
    <feature>/
      data/
        data_sources/
        models/
        repositories/
      domain/
        entities/
        repositories/
        usecases/
      presentation/
        providers/
        widgets/
        screens/
```

Rules for migrated features:

- UI widgets read Riverpod providers and render state only.
- API calls live in `data/data_sources`.
- Repository implementations live in `data/repositories`.
- Business contracts live in `domain/repositories`.
- Business actions live in `domain/usecases`.
- View state and feature dependencies live in `presentation/providers`.
- Do not add new inline `http` calls in screens.
- Do not read bearer tokens directly from `SharedPreferences`.
- Do not show raw backend response bodies to users.

Current feature ownership:

- `admin`
- `auth`
- `chat`
- `delivery`
- `geo`
- `home`
- `invoices`
- `merchant`
- `notifications`
- `order_tracking`
- `products`
- `profile`
- `reviews`
- `staff`
- `wallet`

The old `lib/Views/**` files are now compatibility exports only. New work should
import from `lib/features/**` or `lib/core/**` directly. Shared UI widgets live
under `lib/core/presentation/widgets`.

The wallet transactions screen has the deepest migration so far: it includes
domain entities, a repository contract, a use case, data source/model classes,
and Riverpod presentation providers. Other features now have the same folder
boundaries and providers around their data sources, and should follow the wallet
pattern when their business logic is next touched.
