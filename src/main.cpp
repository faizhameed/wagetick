#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQuickStyle>
#include <QIcon>
#include <QFont>

#include "WageTimer.h"

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);
    app.setOrganizationName(QStringLiteral("WageTick"));
    app.setApplicationName(QStringLiteral("WageTick"));
    app.setApplicationVersion(QStringLiteral("1.0.0"));

    // Clean, modern controls; our QML draws the glass look itself
    QQuickStyle::setStyle(QStringLiteral("Basic"));

    WageTimer wageTimer;

    QQmlApplicationEngine engine;
    engine.rootContext()->setContextProperty(QStringLiteral("wageTimer"), &wageTimer);

    const QUrl url(QStringLiteral("qrc:/qml/main.qml"));
    QObject::connect(
        &engine, &QQmlApplicationEngine::objectCreationFailed,
        &app, []() { QCoreApplication::exit(-1); },
        Qt::QueuedConnection);

    engine.load(url);
    if (engine.rootObjects().isEmpty())
        return -1;

    return app.exec();
}
