import com.android.build.gradle.AppExtension

val android = project.extensions.getByType(AppExtension::class.java)

android.apply {
    flavorDimensions("flavor-type")

    productFlavors {
        create("dev") {
            dimension = "flavor-type"
            applicationId = "com.yourcompany.app.dev"
            resValue(type = "string", name = "app_name", value = "Boilerplate Dev")
        }
        create("staging") {
            dimension = "flavor-type"
            applicationId = "com.yourcompany.app.staging"
            resValue(type = "string", name = "app_name", value = "Boilerplate Staging")
        }
        create("prod") {
            dimension = "flavor-type"
            applicationId = "com.yourcompany.app"
            resValue(type = "string", name = "app_name", value = "Boilerplate")
        }
    }

    buildFeatures.resValues = true
}