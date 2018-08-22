#include "widget.h"
#include "ui_widget.h"
#include <QtXml>

struct Actors {
    Actors(const QStringList& actors) : actors_list(actors) {
        int count = 0;
        foreach(const auto& actor, actors_list) {
            this->actors[actor] = ++count;
        }
    }

    int findActor(const QString& actor) {
        if(actors.contains(actor))
            return actors[actor];
        else {
            auto ind = actors_list.indexOf(QRegExp(actor + "\\w*"));
            if(ind > -1) {
                actors[actor] = ind + 1;
                return ind + 1;
            }
        }
        return -1;
    }

    QStringList actors_list;
    QMap<QString, int> actors;
};

struct Phrase {
    void operator +=(const QString& str) {
        rep += str;
    }
    int id;
    QString rep;
};

Widget::Widget(QWidget *parent) :
    QWidget(parent),
    ui(new Ui::Widget)
{
    ui->setupUi(this);
    connect(ui->textEdit, SIGNAL(textChanged()), this, SLOT(markUp()));
    connect(ui->indentSpinBox, SIGNAL(valueChanged(int)), this, SLOT(markUp()));
}

Widget::~Widget()
{
    delete ui;
}

void Widget::markUp() {
    auto str = ui->textEdit->toPlainText();
    QStringList lines =str.split('\n');
    QStringList actors = lines.first().split(" ", QString::SkipEmptyParts);
    lines.removeFirst();
    QDomDocument doc;
    auto conversation = doc.createElement("vim-conversation");
    conversation.setAttribute("fill-style", "background");
    auto speakers = doc.createElement("vim-conversation-speakers");
    conversation.appendChild(speakers);
    int count = 0;
    foreach(const auto& actor, actors) {
        auto speaker = doc.createElement("vim-conversation-speaker");
        speaker.setAttribute("id", ++count);
        speaker.appendChild(doc.createTextNode(actor));
        speakers.appendChild(speaker);
    }
    Actors actors_struct(actors);
    QList<Phrase> phrases;
    for(const auto& str : lines) {
        if(str.isEmpty())
            continue;
        auto lst = str.split(" ", QString::SkipEmptyParts);
        auto ind = actors_struct.findActor(lst.first());
        if(ind > -1) {
            lst.removeFirst();
            phrases.append({ind, lst.join(" ")});
        } else {
            if(phrases.empty()) {
                phrases.append({1, lst.join(" ")});
            } else {
                phrases.back() += " " + lst.join(" ");
            }
        }
    }
    auto content = doc.createElement("vim-conversation-content");
    foreach(const auto& phrase, phrases) {
        auto item = doc.createElement("vim-conversation-item");
        item.setAttribute("speaker-id", phrase.id);
        item.appendChild(doc.createTextNode(phrase.rep));
        content.appendChild(item);
    }
    conversation.appendChild(content);
    doc.appendChild(conversation);
    ui->textEdit_2->setPlainText(doc.toString(ui->indentSpinBox->value()));
}
