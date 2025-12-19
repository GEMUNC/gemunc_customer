import 'package:eshop_plus/core/constants/themeConstants.dart';
import 'package:eshop_plus/ui/profile/customerSupport/blocs/addOrEditTicketCubit.dart';
import 'package:eshop_plus/ui/profile/customerSupport/blocs/getTicketCubit.dart';
import 'package:eshop_plus/ui/profile/customerSupport/blocs/getTicketTypesCubit.dart';
import 'package:eshop_plus/ui/profile/customerSupport/models/ticket.dart';
import 'package:eshop_plus/commons/widgets/customAppbar.dart';
import 'package:eshop_plus/commons/widgets/customBottomButtonContainer.dart';
import 'package:eshop_plus/commons/widgets/customCircularProgressIndicator.dart';
import 'package:eshop_plus/commons/widgets/customDropDownContainer.dart';
import 'package:eshop_plus/commons/widgets/customRoundedButton.dart';
import 'package:eshop_plus/commons/widgets/customTextContainer.dart';
import 'package:eshop_plus/commons/widgets/customTextFieldContainer.dart';
import 'package:eshop_plus/commons/widgets/error_screen.dart';

import 'package:eshop_plus/core/api/apiEndPoints.dart';
import 'package:eshop_plus/utils/designConfig.dart';
import 'package:eshop_plus/core/localization/labelKeys.dart';
import 'package:eshop_plus/utils/utils.dart';
import 'package:eshop_plus/utils/validator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';

class AskQueryScreen extends StatefulWidget {
  final Ticket? ticket;
  final TicketCubit ticketCubit;
  AskQueryScreen({Key? key, this.ticket, required this.ticketCubit})
      : super(key: key);

  static Widget getRouteInstance() {
    final arguments = Get.arguments as Map<String, dynamic>;
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => AddOrEditTicketCubit(),
        ),
        BlocProvider(
          create: (context) => TicketTypeCubit(),
        ),
      ],
      child: AskQueryScreen(
        ticketCubit: arguments['ticketCubit'] as TicketCubit,
        ticket: arguments['ticket'] as Ticket?,
      ),
    );
  }

  @override
  _AskQueryScreenState createState() => _AskQueryScreenState();
}

class _AskQueryScreenState extends State<AskQueryScreen> {
  final _formKey = GlobalKey<FormState>();
  Map<String, TextEditingController> controllers = {};
  Map<String, FocusNode> focusNodes = {};
  int? _seletedTicketTypeId;
  int? _seletedTicketStatusId;
  final List formFields = [
    selectIssueTypeKey,
    emailKey,
    subjectKey,
    messageKey
  ];
  @override
  void initState() {
    super.initState();
    context.read<TicketTypeCubit>().getTicketTypes();
    formFields.forEach((key) {
      controllers[key] = TextEditingController();
      focusNodes[key] = FocusNode();
    });
    if (widget.ticket != null) {
      _seletedTicketTypeId = widget.ticket!.ticketTypeId!;
      controllers[emailKey]!.text = widget.ticket!.email ?? '';
      controllers[subjectKey]!.text = widget.ticket!.subject ?? '';
      controllers[messageKey]!.text = widget.ticket!.description ?? '';
    }
  }

  @override
  void dispose() {
    controllers.forEach((key, controller) {
      controller.dispose();
    });
    focusNodes.forEach((key, focusNode) {
      focusNode.dispose();
    });
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TicketTypeCubit, TicketTypeState>(
      builder: (context, state) {
        return Scaffold(
          backgroundColor: Theme.of(    context).colorScheme.primaryContainer,
            appBar: const CustomAppbar(titleKey: customerSupportKey),
            bottomNavigationBar: buildSendButton(state),
            body: GestureDetector(
              onTap: () => FocusScope.of(context).unfocus(),
              child: state is TicketTypeFetchSuccess
                  ? buildForm(state)
                  : state is TicketTypeFetchFailure
                      ? ErrorScreen(
                          text: state.errorMessage,
                          onPressed: () =>
                              context.read<TicketTypeCubit>().getTicketTypes())
                      : CustomCircularProgressIndicator(
                          indicatorColor: Theme.of(context).colorScheme.primary,
                        ),
            ));
      },
    );
  }

  Widget buildForm(TicketTypeFetchSuccess state) {
    return Padding(
      padding: const EdgeInsets.all(appContentHorizontalPadding),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              CustomTextContainer(
                  textKey: selectYourQueryKey,
                  style: Theme.of(context).textTheme.titleMedium),
              DesignConfig.defaultHeightSizedBox,
              buildTicketTypeDropDown(state),
              CustomTextFieldContainer(
                hintTextKey: emailKey,
                textEditingController: controllers[emailKey]!,
                focusNode: focusNodes[emailKey],
                textInputAction: TextInputAction.next,
                keyboardType: TextInputType.emailAddress,
                validator: (v) => Validator.validateEmail(context, v),
                onFieldSubmitted: (v) {
                  FocusScope.of(context).requestFocus(focusNodes[subjectKey]);
                },
              ),
              CustomTextFieldContainer(
                hintTextKey: subjectKey,
                textEditingController: controllers[subjectKey]!,
                focusNode: focusNodes[subjectKey],
                textInputAction: TextInputAction.next,
                validator: (v) => Validator.emptyValueValidation(context, v),
                onFieldSubmitted: (v) {
                  FocusScope.of(context).requestFocus(focusNodes[messageKey]);
                },
              ),
              CustomTextFieldContainer(
                hintTextKey: messageKey,
                textEditingController: controllers[messageKey]!,
                focusNode: focusNodes[messageKey],
                textInputAction: TextInputAction.done,
                maxLines: 5,
                validator: (v) => Validator.emptyValueValidation(context, v),
                onFieldSubmitted: (v) {
                  focusNodes[messageKey]!.unfocus();
                },
              ),
              //this is for the ticket status only for edit tickets and not for pending tickets
              if (widget.ticket != null && widget.ticket!.status!=1) buildTicketStatusDropDown(),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildTicketTypeDropDown(TicketTypeFetchSuccess state) {
    return Container(
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
          border: Border.all(
              color: Theme.of(context).inputDecorationTheme.iconColor!)),
      padding: const EdgeInsetsDirectional.all(15),
      child: CustomDropDownContainer(
        labelKey: selectIssueTypeKey,
        dropDownDisplayLabels:
            state.ticketTypes.map((e) => e.title ?? "").toList(),
        selectedValue: _seletedTicketTypeId,
        onChanged: (value) {
          setState(() {
            _seletedTicketTypeId = value != null ? value as int : null;
          });
        },
        values: state.ticketTypes.map((e) => e.id ?? "").toList(),
      ),
    );
  }

  buildTicketStatusDropDown() {
    List<String> displayLabels = [resolvedKey];
    List<int> values = [3];
    
    if (widget.ticket?.status == 4) {
      displayLabels.add(reopenedKey);
      values.add(5);
    }
    
    return Container(
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
          border: Border.all(
              color: Theme.of(context).inputDecorationTheme.iconColor!)),
      padding: const EdgeInsetsDirectional.all(15),
      child: CustomDropDownContainer(
        labelKey: selectTicketStatusKey,
        dropDownDisplayLabels: displayLabels,
        selectedValue: _seletedTicketStatusId,
        onChanged: (value) {
          setState(() {
            _seletedTicketStatusId = value;
          });
        },
        values: values,
      ),
    );
  }

  Widget buildSendButton(TicketTypeState ticketstate) {
    return BlocConsumer<AddOrEditTicketCubit, AddOrEditTicketState>(
      listener: (context, state) {
        if (state is AddOrEditTicketSuccess) {
          List<Ticket> tickets = [];
          if (widget.ticketCubit.state is TicketFetchSuccess) {
            tickets = (widget.ticketCubit.state as TicketFetchSuccess).tickets;
          }
          final index =
              tickets.indexWhere((element) => element.id == state.ticket.id);

          if (index != -1) {
            tickets[index] = state.ticket;
          } else {
            tickets.insert(0, state.ticket);
          }
          widget.ticketCubit.emitSuccessState(tickets, tickets.length);

          Utils.showSnackBar(message: state.successMessage, context: context);
          Future.delayed(const Duration(milliseconds: 200), () {
            Navigator.of(context).pop();
          });
        }
        if (state is AddOrEditTicketFailure) {
          Utils.showSnackBar(message: state.errorMessage, context: context);
        }
      },
      builder: (context, state) {
        return ticketstate is TicketTypeFetchSuccess
            ? Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                ),
                child: CustomBottomButtonContainer(
                  child: CustomRoundedButton(
                    widthPercentage: 1.0,
                    buttonTitle: sendQueryKey,
                    showBorder: false,
                    child: state is AddOrEditTicketProgress
                        ? const CustomCircularProgressIndicator()
                        : null,
                    onTap: () {
                      FocusScope.of(context).unfocus();
                      if (_formKey.currentState!.validate()) {
                        if (state is! AddOrEditTicketProgress) {
                          if (_seletedTicketTypeId == null) {
                            Utils.showSnackBar(
                                message: plsSelectIssueTypeKey,
                                context: context);
                            return;
                          }
                          Map<String, dynamic> params = {
                            ApiURL.ticketTypeIdApiKey: _seletedTicketTypeId,
                            ApiURL.emailApiKey:
                                controllers[emailKey]!.text.toString(),
                            ApiURL.subjectApiKey:
                                controllers[subjectKey]!.text.toString(),
                            ApiURL.descriptionApiKey:
                                controllers[messageKey]!.text.toString(),
                          };
                          if (widget.ticket != null ) {
                        
                            params[ApiURL.ticketIdApiKey] = widget.ticket!.id;
                      if (_seletedTicketStatusId != null)       params[ApiURL.statusApiKey] =
                                _seletedTicketStatusId;
                          }
                          context.read<AddOrEditTicketCubit>().addOrEditTicket(
                              params: params,
                              isEdit: widget.ticket != null ? true : false);
                        }
                      }
                    },
                  ),
                ),
              )
            : SizedBox.shrink();
      },
    );
  }
}
